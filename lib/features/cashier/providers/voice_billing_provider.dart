import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../products/providers/products_provider.dart';
import 'cart_provider.dart';
import '../../../models/product.dart';

class VoiceBillingState {
  final bool isRecording;
  final bool isProcessing;
  final String? lastTranscript;
  final String? errorMessage;
  final String? successMessage;
  final int updateId;

  VoiceBillingState({
    this.isRecording = false, // Do not auto-start recording by default
    this.isProcessing = false,
    this.lastTranscript,
    this.errorMessage,
    this.successMessage,
    this.updateId = 0,
  });

  VoiceBillingState copyWith({
    bool? isRecording,
    bool? isProcessing,
    String? lastTranscript,
    String? errorMessage,
    String? successMessage,
    bool? clearError,
    bool? clearSuccess,
    bool? clearTranscript,
    int? updateId,
  }) {
    return VoiceBillingState(
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      lastTranscript: clearTranscript == true ? null : (lastTranscript ?? this.lastTranscript),
      errorMessage: clearError == true ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess == true ? null : (successMessage ?? this.successMessage),
      updateId: updateId ?? this.updateId,
    );
  }
}

class VoiceBillingNotifier extends Notifier<VoiceBillingState> {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final String _wsUrl = 'ws://127.0.0.1:8766';
  Process? _pythonProcess;
  bool _isPythonStarting = false;
  bool _isConnected = false;
  bool _isConnecting = false;

  @override
  VoiceBillingState build() {
    ref.onDispose(() {
      _reconnectTimer?.cancel();
      _channel?.sink.close();
      if (_pythonProcess != null) {
        debugPrint('Killing Python process on dispose...');
        _pythonProcess!.kill(ProcessSignal.sigterm);
      }
    });
    
    // Connect and start backend on startup for continuous AI assistance
    Future.microtask(_ensureBackendRunning);
    
    return VoiceBillingState(isRecording: false);
  }

  bool _isEnsuringBackend = false;

  Future<void> _ensureBackendRunning() async {
    if (_isConnected || _isEnsuringBackend) return;
    _isEnsuringBackend = true;
    
    // First try to connect, maybe it is already running
    try {
      final testChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      await testChannel.ready.timeout(const Duration(seconds: 5));
      testChannel.sink.close();
      await _connectWebSocket();
      _isEnsuringBackend = false;
      return;
    } catch (e) {
      // Backend not reachable, starting python process
      debugPrint('Backend not reachable, starting python process...');
      
      // KILL ANY ZOMBIE PROCESSES ON PORT 8766 BEFORE STARTING!
      if (Platform.isWindows) {
        try {
          final result = await Process.run('cmd', ['/c', 'netstat -ano | findstr :8766']);
          final lines = result.stdout.toString().trim().split('\n');
          for (var line in lines) {
            if (line.contains('LISTENING')) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 5) {
                final pid = parts.last;
                await Process.run('taskkill', ['/F', '/PID', pid]);
                debugPrint('Killed zombie python process on port 8766 (PID: $pid)');
              }
            }
          }
          await Future.delayed(const Duration(seconds: 1));
        } catch (_) {}
      }
      
      final Map<String, String> env = Map.from(Platform.environment);
      env['PYTHONIOENCODING'] = 'utf-8';
      
      String pythonPath = 'python';
      if (Platform.isWindows) {
        pythonPath = 'voice_assistant_temp\\venv\\Scripts\\python.exe';
      } else {
        pythonPath = 'voice_assistant_temp/venv/bin/python';
      }
      
      _pythonProcess = await Process.start(
        pythonPath,
        ['-u', 'voice_assistant_temp/voice_assistant.py'],
        environment: env,
        runInShell: false,
      );

      _pythonProcess!.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('Python: $data');
      });

      _pythonProcess!.stderr.transform(utf8.decoder).listen((data) {
        debugPrint('Python Error: $data');
      });

      // Poll for the python server to start instead of waiting a hard 8 seconds
      int pollAttempts = 0;
      while (!_isConnected && pollAttempts < 15) {
        await Future.delayed(const Duration(seconds: 1));
        if (_isConnected) break;
        try {
          final testChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));
          await testChannel.ready.timeout(const Duration(seconds: 1));
          testChannel.sink.close();
          await _connectWebSocket();
          break;
        } catch (_) {}
        pollAttempts++;
      }
    }
    
    _isEnsuringBackend = false;
  }

  Future<void> _connectWebSocket() async {
    if (_isConnected) return;
    
    // If a connection attempt is already in progress, wait for it to finish
    int waitCount = 0;
    while (_isConnecting && waitCount < 50) { // wait max 5 seconds
      await Future.delayed(const Duration(milliseconds: 100));
      if (_isConnected) return;
      waitCount++;
    }
    
    if (_isConnected) return;
    _isConnecting = true;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      await _channel!.ready;
      _isConnected = true;
      _isConnecting = false;
      debugPrint('Connected to Voice Backend WebSocket');
      
      if (state.isRecording) {
        _channel!.sink.add('{"type": "start_recording"}');
      }
      
      _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message.toString());
        },
        onError: (error) {
          if (_pythonProcess != null) {
            debugPrint('WebSocket Error: $error');
          }
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          if (_pythonProcess != null) {
            debugPrint('WebSocket Closed');
          }
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      // Don't spam the console with connection refused errors during boot/reconnect polling
      if (!e.toString().contains('SocketException')) {
        debugPrint('WebSocket Connection Error: $e');
      }
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    // If we haven't tried to start the process, don't spam reconnects as fast
    final int delaySeconds = _pythonProcess == null ? 15 : 5;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _connectWebSocket();
    });
  }

  Future<void> _handleWebSocketMessage(String message) async {
    try {
      final data = jsonDecode(message);
      
      if (data is Map && data['type'] == 'error') {
        state = state.copyWith(isProcessing: false, errorMessage: data['message'] ?? 'Voice processing failed');
        return;
      }
      
      if (data is Map && data['type'] == 'processing') {
        state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
        return;
      }
      
      if (data is Map && data['type'] == 'transcript') {
        state = state.copyWith(lastTranscript: data['text']);
        return;
      }
      
      if (data is Map && data['type'] == 'command') {
        final action = data['action'];
        if (action == 'clear_cart') {
          ref.read(cartProvider.notifier).clearCart();
          state = state.copyWith(successMessage: 'Cart cleared by voice command');
        } else if (action == 'checkout') {
          // Trigger checkout state somehow, maybe just set a flag for UI to pick up
          state = state.copyWith(successMessage: 'Checkout triggered by voice');
        }
        return;
      }
      
      state = state.copyWith(isProcessing: false, clearError: true, clearSuccess: true);
      
      if (data is Map && data.containsKey('items')) {
        final items = data['items'] as List;
        final unmatchedItems = (data['unmatched_items'] as List?)?.cast<String>() ?? [];
        
        if (items.isEmpty && unmatchedItems.isEmpty) {
          // Empty background update (noise). Clear processing state.
          state = state.copyWith(isProcessing: false);
          // Only clear transcript if we aren't currently showing suggestions to the user
          if (state.successMessage == null || !state.successMessage!.contains('Multiple matches')) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              // Ensure we still aren't showing suggestions before clearing
              if (state.successMessage == null || !state.successMessage!.contains('Multiple matches')) {
                state = state.copyWith(clearTranscript: true);
              }
            });
          }
          return;
        }
        
        // Wait for products to be loaded (especially if triggered from a screen where it wasn't watched yet)
        List<Product> products = [];
        try {
          products = await ref.read(productsProvider.future);
        } catch (e) {
          final stateVal = ref.read(productsProvider).value;
          if (stateVal != null) products = stateVal;
        }
        
        int addedCount = 0;
        List<String> addedItemNames = [];
        List<String> notFoundList = List.from(unmatchedItems);
        List<String> suggestionList = [];
        
        final logFile = File(r'd:\Billing-software-main\voice_debug.txt');
        String logContent = '--- VOICE BILLING UPDATE ---\nItems: $items\nProducts in DB: ${products.length}\n';
        
        for (final item in items) {
          final productName = item['product']?.toString().toLowerCase().trim() ?? '';
          final rawProductName = item['product']?.toString().trim() ?? '';
          final qty = (item['qty'] as num?)?.toDouble() ?? 1.0;
          
          logContent += 'Processing item: "$productName"\n';
          
          if (productName.isNotEmpty) {
            Product? matchedProduct;
            bool multipleMatches = false;
            
            try {
              // Try exact match first
              matchedProduct = products.firstWhere((p) => p.name.toLowerCase().trim() == productName);
            } catch (_) {
              // Fallback to contains
              final containsMatches = products.where((p) => p.name.toLowerCase().contains(productName)).toList();
              if (containsMatches.isNotEmpty) {
                matchedProduct = containsMatches.first; // Just pick the best/first match instead of refusing!
              } else {
                matchedProduct = null;
              }
            }

            if (matchedProduct != null) {
              logContent += '-> Matched exactly/singularly: ${matchedProduct.name}\n';
              final cartNotifier = ref.read(cartProvider.notifier);
              cartNotifier.addProduct(matchedProduct);
              
              if (qty > 1) {
                Future.microtask(() {
                  final cartState = ref.read(cartProvider);
                  final cartItem = cartState.items.firstWhere((i) => i.product.id == matchedProduct!.id);
                  cartNotifier.updateQuantity(matchedProduct!.id!, cartItem.quantity + qty - 1);
                });
              }
              addedCount++;
              
              // Build a clean English string like "2 Milk" or "1 Cake"
              String qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
              addedItemNames.add("$qtyStr ${matchedProduct.name}");
            } else if (multipleMatches) {
              logContent += '-> Multiple matches found\n';
              suggestionList.add(rawProductName);
            } else {
              logContent += '-> Not found in DB\n';
              notFoundList.add(rawProductName);
            }
          }
        }
        
        logContent += 'Added: $addedCount, Suggestions: $suggestionList, NotFound: $notFoundList\n';
        try { logFile.writeAsStringSync(logContent, mode: FileMode.append); } catch (e) {}
        
        if (addedCount > 0) {
          state = state.copyWith(
            isProcessing: false, 
            successMessage: 'Added $addedCount items', 
            lastTranscript: state.lastTranscript?.trim(),
            clearTranscript: false
          );
        } else if (suggestionList.isNotEmpty) {
          state = state.copyWith(successMessage: 'Multiple matches found for ${suggestionList.join(", ")}. Select below.');
        }
        
        if (notFoundList.isNotEmpty) {
          state = state.copyWith(errorMessage: 'No product available: ${notFoundList.join(", ")}');
        }
        
        if (addedCount == 0 && notFoundList.isEmpty && suggestionList.isEmpty) {
          // Quietly ignore to prevent annoying errors during normal conversation
          // state = state.copyWith(errorMessage: 'No matching products found from voice input.');
        }

        // Update transcript to English names so user sees what was understood
        String? newTranscript;
        
        if (addedItemNames.isNotEmpty) {
            newTranscript = addedItemNames.join(", ");
        }
        
        // Suggestions override the transcript so the user can search them
        if (suggestionList.isNotEmpty) {
           newTranscript = suggestionList.first;
        }

        state = state.copyWith(
          isProcessing: false,
          lastTranscript: newTranscript ?? state.lastTranscript,
          updateId: state.updateId + 1,
        );
        
        // Auto-clear transcript after 1.5s so search overlay disappears and cart is visible
        // ONLY if there are no suggestions pending selection
        debugPrint('Will clear transcript? ${suggestionList.isEmpty}. Suggestion list: $suggestionList');
        if (suggestionList.isEmpty) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            debugPrint('Clearing transcript now!');
            // Clear transcript in state which will clear the search bar in UI
            state = state.copyWith(clearTranscript: true);
          });
        }
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
      state = state.copyWith(isProcessing: false, errorMessage: 'Failed to process voice response');
    }
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      state = state.copyWith(isRecording: false, isProcessing: true);
      _sendToBackend('{"type": "stop_recording"}');
    } else {
      state = state.copyWith(
        isRecording: true, 
        clearError: true, 
        clearSuccess: true,
        clearTranscript: true, // Clear previous transcript so new ones trigger a change
      );
      await _ensureBackendRunning();
      
      if (_isConnected) {
        state = state.copyWith(
          isRecording: true,
          isProcessing: false,
        );
        _sendToBackend('{"type": "start_recording"}');
      } else {
        state = state.copyWith(
          isRecording: false,
          isProcessing: false, 
          errorMessage: 'AI Engine is connecting. Please try again in a moment.'
        );
      }
    }
  }
  
  void _sendToBackend(String payload) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(payload);
    } else {
      state = state.copyWith(isProcessing: false, errorMessage: 'Not connected to Voice Backend');
    }
  }
}

final voiceBillingProvider = NotifierProvider<VoiceBillingNotifier, VoiceBillingState>(VoiceBillingNotifier.new);
