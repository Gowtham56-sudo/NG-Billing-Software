package com.example.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.AppDatabase
import com.example.data.BillHistory
import com.example.data.Product
import com.example.data.TeaRepository
import com.example.printer.BluetoothPrinterManager
import com.example.printer.CartItemPrintData
import com.example.printer.DiscoveredDevice
import com.example.printer.PrinterConnectionStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class CartItem(
    val product: Product,
    val quantity: Int = 1
)

sealed class ActiveDialog {
    object AddProduct : ActiveDialog()
    data class EditProduct(val product: Product) : ActiveDialog()
    data class ReceiptPreview(val receiptText: String, val isTestPrint: Boolean = false) : ActiveDialog()
    object ShopSettings : ActiveDialog()
}

class BillingViewModel(application: Application) : AndroidViewModel(application) {

    private val repository: TeaRepository
    val printerManager: BluetoothPrinterManager = BluetoothPrinterManager(application)

    init {
        val database = AppDatabase.getDatabase(application)
        repository = TeaRepository(database.productDao(), database.billHistoryDao())
        viewModelScope.launch {
            repository.ensureInitialData()
        }
    }

    // Products Flow from DB
    val rawProducts: StateFlow<List<Product>> = repository.allProducts.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    // Bill History Flow from DB
    val billHistory: StateFlow<List<BillHistory>> = repository.allBills.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    // UI state filters
    private val _selectedCategory = MutableStateFlow("All")
    val selectedCategory: StateFlow<String> = _selectedCategory.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    // Filtered Products
    val filteredProducts: StateFlow<List<Product>> = combine(
        rawProducts,
        _selectedCategory,
        _searchQuery
    ) { products, category, query ->
        products.filter { product ->
            val matchesCategory = (category == "All" || product.category.equals(category, ignoreCase = true))
            val matchesQuery = query.isBlank() || product.name.contains(query, ignoreCase = true)
            matchesCategory && matchesQuery
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    // Cart State
    private val _cartItems = MutableStateFlow<List<CartItem>>(emptyList())
    val cartItems: StateFlow<List<CartItem>> = _cartItems.asStateFlow()

    private val _paymentMode = MutableStateFlow("Cash")
    val paymentMode: StateFlow<String> = _paymentMode.asStateFlow()

    private val _shopName = MutableStateFlow("Chai & Snacks Corner")
    val shopName: StateFlow<String> = _shopName.asStateFlow()

    private val _discountPercent = MutableStateFlow(0.0)
    val discountPercent: StateFlow<Double> = _discountPercent.asStateFlow()

    private val _activeDialog = MutableStateFlow<ActiveDialog?>(null)
    val activeDialog: StateFlow<ActiveDialog?> = _activeDialog.asStateFlow()

    private val _isPrinting = MutableStateFlow(false)
    val isPrinting: StateFlow<Boolean> = _isPrinting.asStateFlow()

    private val _printerDevices = MutableStateFlow<List<DiscoveredDevice>>(emptyList())
    val printerDevices: StateFlow<List<DiscoveredDevice>> = _printerDevices.asStateFlow()

    private val _toastMessage = MutableStateFlow<String?>(null)
    val toastMessage: StateFlow<String?> = _toastMessage.asStateFlow()

    // Calculated totals
    val subtotal: Double
        get() = _cartItems.value.sumOf { it.product.price * it.quantity }

    val discountAmount: Double
        get() = subtotal * (_discountPercent.value / 100.0)

    val grandTotal: Double
        get() = (subtotal - discountAmount).coerceAtLeast(0.0)

    val totalItemCount: Int
        get() = _cartItems.value.sumOf { it.quantity }

    // Category list
    val categories = listOf("All", "Tea & Coffee", "Snacks", "Bakery")

    // Actions
    fun setSelectedCategory(category: String) {
        _selectedCategory.value = category
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun setPaymentMode(mode: String) {
        _paymentMode.value = mode
    }

    fun setShopName(name: String) {
        _shopName.value = name
    }

    fun setDiscountPercent(percent: Double) {
        _discountPercent.value = percent
    }

    fun showDialog(dialog: ActiveDialog?) {
        _activeDialog.value = dialog
    }

    fun dismissDialog() {
        _activeDialog.value = null
    }

    fun clearToast() {
        _toastMessage.value = null
    }

    // Cart Operations
    fun addToCart(product: Product) {
        val currentList = _cartItems.value.toMutableList()
        val index = currentList.indexOfFirst { it.product.id == product.id }
        if (index >= 0) {
            val existing = currentList[index]
            currentList[index] = existing.copy(quantity = existing.quantity + 1)
        } else {
            currentList.add(CartItem(product = product, quantity = 1))
        }
        _cartItems.value = currentList
    }

    fun decrementQuantity(product: Product) {
        val currentList = _cartItems.value.toMutableList()
        val index = currentList.indexOfFirst { it.product.id == product.id }
        if (index >= 0) {
            val existing = currentList[index]
            if (existing.quantity > 1) {
                currentList[index] = existing.copy(quantity = existing.quantity - 1)
            } else {
                currentList.removeAt(index)
            }
            _cartItems.value = currentList
        }
    }

    fun removeFromCart(product: Product) {
        _cartItems.value = _cartItems.value.filterNot { it.product.id == product.id }
    }

    fun clearCart() {
        _cartItems.value = emptyList()
        _discountPercent.value = 0.0
    }

    // Product CRUD
    fun addProduct(name: String, price: Double, category: String, imagePath: String?) {
        viewModelScope.launch {
            val product = Product(
                name = name.trim(),
                price = price,
                category = category,
                imagePath = imagePath
            )
            repository.insertProduct(product)
            _toastMessage.value = "'${name}' added to products"
            dismissDialog()
        }
    }

    fun updateProduct(product: Product) {
        viewModelScope.launch {
            repository.updateProduct(product)
            _toastMessage.value = "'${product.name}' updated"
            dismissDialog()
        }
    }

    fun deleteProduct(product: Product) {
        viewModelScope.launch {
            repository.deleteProduct(product)
            // also remove from active cart if present
            removeFromCart(product)
            _toastMessage.value = "'${product.name}' deleted"
        }
    }

    // Printer Actions
    fun scanPrinterDevices() {
        _printerDevices.value = printerManager.getPairedDevices()
        _toastMessage.value = "Found ${_printerDevices.value.size} Bluetooth printers"
    }

    fun connectPrinter(device: DiscoveredDevice) {
        viewModelScope.launch {
            _isPrinting.value = true
            val success = printerManager.connectToDevice(device.macAddress, device.name)
            _isPrinting.value = false
            if (success) {
                _toastMessage.value = "Connected to ${device.name}"
            } else {
                _toastMessage.value = "Failed to connect printer"
            }
        }
    }

    fun doTestPrint() {
        viewModelScope.launch {
            _isPrinting.value = true
            printerManager.printTestReceipt(_shopName.value)
            _isPrinting.value = false
            val text = printerManager.lastPrintedReceipt.value ?: "Test Receipt Sample"
            _activeDialog.value = ActiveDialog.ReceiptPreview(text, isTestPrint = true)
        }
    }

    // Checkout & Bill Printing
    fun processAndPrintBill() {
        if (_cartItems.value.isEmpty()) {
            _toastMessage.value = "Cart is empty! Add products first."
            return
        }

        viewModelScope.launch {
            _isPrinting.value = true

            val billNum = "TB-" + (System.currentTimeMillis() % 100000).toString()
            val printItems = _cartItems.value.map {
                CartItemPrintData(it.product.name, it.quantity, it.product.price)
            }

            // Print ESC/POS command
            printerManager.printBillReceipt(
                shopName = _shopName.value,
                billNumber = billNum,
                items = printItems,
                subtotal = subtotal,
                tax = 0.0,
                discount = discountAmount,
                total = grandTotal,
                paymentMode = _paymentMode.value
            )

            // Save to Local Room DB
            val itemsJsonString = _cartItems.value.joinToString("; ") {
                "${it.product.name} x${it.quantity} (Rs ${it.product.price * it.quantity})"
            }

            val historyRecord = BillHistory(
                billNumber = "#$billNum",
                itemsJson = itemsJsonString,
                subtotal = subtotal,
                tax = 0.0,
                discount = discountAmount,
                total = grandTotal,
                paymentMode = _paymentMode.value,
                timestamp = System.currentTimeMillis()
            )
            repository.insertBill(historyRecord)

            val receiptText = printerManager.lastPrintedReceipt.value ?: ""
            _isPrinting.value = false

            // Clear current bill
            clearCart()

            // Show Receipt Preview Dialog
            _activeDialog.value = ActiveDialog.ReceiptPreview(receiptText, isTestPrint = false)
            _toastMessage.value = "Bill #$billNum created and printed! ✅"
        }
    }

    fun deleteBillHistory(billId: Int) {
        viewModelScope.launch {
            repository.deleteBillById(billId)
            _toastMessage.value = "Bill record deleted"
        }
    }

    fun clearAllBillHistory() {
        viewModelScope.launch {
            repository.clearBillHistory()
            _toastMessage.value = "All bill history cleared"
        }
    }
}
