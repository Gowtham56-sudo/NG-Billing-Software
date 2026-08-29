import 'dart:async';
import 'dart:convert';
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
    this.isRecording = false,
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
  final String _wsUrl = 'ws://localhost:8765';
  bool _isConnected = false;

  @override
  VoiceBillingState build() {
    ref.onDispose(() {
      _reconnectTimer?.cancel();
      _channel?.sink.close();
    });
    
    Future.microtask(_connectWebSocket);
    return VoiceBillingState(isRecording: false);
  }

  void _connectWebSocket() {
    if (_isConnected) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;
      debugPrint('Connected to Voice Backend WebSocket');
      
      _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message.toString());
        },
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket Closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _connectWebSocket();
    });
  }

  Future<void> _handleWebSocketMessage(String message) async {
    try {
      final data = jsonDecode(message);
      
      if (data['status'] == 'listening') {
        state = state.copyWith(isRecording: true, isProcessing: false, clearError: true, clearSuccess: true);
        return;
      }
      
      if (data['status'] == 'processing') {
        final partial = data['transcript'] as String?;
        state = state.copyWith(
          isRecording: true, 
          isProcessing: false, 
          clearError: true, 
          clearSuccess: true,
          lastTranscript: partial
        );
        return;
      }

      if (data['status'] == 'stopped') {
        state = state.copyWith(
          isRecording: false,
          isProcessing: false,
          clearError: true,
          clearSuccess: true,
        );
        return;
      }
      
      if (data['error'] != null) {
         state = state.copyWith(
          isProcessing: false,
          errorMessage: data['error'],
        );
        return;
      }
      
      if (data['type'] == 'bill_update') {
        state = state.copyWith(isRecording: true, isProcessing: false, clearError: true, clearSuccess: true);
        
        final items = data['items'] as List<dynamic>? ?? [];
        final unrecognized = data['unrecognized'] as List<dynamic>? ?? [];
        
        List<Product> products = [];
        try {
          products = await ref.read(productsProvider.future);
        } catch (e) {
          final stateVal = ref.read(productsProvider).value;
          if (stateVal != null) products = stateVal;
        }
        
        int addedCount = 0;
        List<String> addedItemNames = [];
        
        for (final item in items) {
          final productName = item['product']?.toString().toLowerCase().trim() ?? '';
          final productId = item['product_id'] as int?;
          final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
          
          Product? matchedProduct;
          if (productId != null) {
            try {
              matchedProduct = products.firstWhere((p) => p.id == productId);
            } catch (_) {}
          }
          
          if (matchedProduct == null && productName.isNotEmpty) {
            try {
               matchedProduct = products.firstWhere((p) => p.name.toLowerCase().trim() == productName);
            } catch (_) {
               final containsMatches = products.where((p) => p.name.toLowerCase().contains(productName)).toList();
               if (containsMatches.isNotEmpty) matchedProduct = containsMatches.first;
            }
          }

          if (matchedProduct != null) {
            final cartNotifier = ref.read(cartProvider.notifier);
            cartNotifier.addProduct(matchedProduct, qty);
            
            addedCount++;
            String qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
            addedItemNames.add("$qtyStr ${matchedProduct.name}");
          }
        }
        
        if (addedCount > 0) {
          state = state.copyWith(
            successMessage: 'Added $addedCount items', 
            lastTranscript: addedItemNames.join(", "),
            clearTranscript: false,
            updateId: state.updateId + 1
          );
        }
        
        if (unrecognized.isNotEmpty) {
          state = state.copyWith(errorMessage: 'Unrecognized: ${unrecognized.map((u) => u['text']).join(", ")}');
        }
        
        Future.delayed(const Duration(milliseconds: 2000), () {
            state = state.copyWith(clearTranscript: true);
        });
      }
    } catch (e) {
      debugPrint('Error processing response: $e');
    }
  }

  void toggleRecording() {
    if (state.isRecording) {
      state = state.copyWith(isRecording: false, isProcessing: true);
      _sendToBackend('{"command": "stop"}');
    } else {
      if (!_isConnected) _connectWebSocket();
      state = state.copyWith(
        isRecording: true,
        clearError: true,
        clearSuccess: true,
        clearTranscript: true,
      );
      _sendToBackend('{"command": "start"}');
    }
  }
  
  void _sendToBackend(String payload) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(payload);
    } else {
      state = state.copyWith(isProcessing: false, errorMessage: 'Voice server disconnected. Reconnecting...');
      _connectWebSocket();
    }
  }
}

final voiceBillingProvider = NotifierProvider<VoiceBillingNotifier, VoiceBillingState>(VoiceBillingNotifier.new);
