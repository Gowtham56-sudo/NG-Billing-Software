package com.example.data

import kotlinx.coroutines.flow.Flow

class TeaRepository(
    private val productDao: ProductDao,
    private val billHistoryDao: BillHistoryDao
) {
    val allProducts: Flow<List<Product>> = productDao.getAllProducts()
    val allBills: Flow<List<BillHistory>> = billHistoryDao.getAllBills()

    suspend fun insertProduct(product: Product): Long = productDao.insertProduct(product)

    suspend fun updateProduct(product: Product) = productDao.updateProduct(product)

    suspend fun deleteProduct(product: Product) = productDao.deleteProduct(product)

    suspend fun deleteProductById(id: Int) = productDao.deleteProductById(id)

    suspend fun insertBill(bill: BillHistory): Long = billHistoryDao.insertBill(bill)

    suspend fun deleteBillById(id: Int) = billHistoryDao.deleteBillById(id)

    suspend fun clearBillHistory() = billHistoryDao.clearHistory()

    suspend fun ensureInitialData() {
        if (productDao.getProductCount() == 0) {
            val initialProducts = listOf(
                Product(name = "Masala Chai", price = 15.0, category = "Tea & Coffee"),
                Product(name = "Ginger Tea", price = 15.0, category = "Tea & Coffee"),
                Product(name = "Cardamom Chai", price = 20.0, category = "Tea & Coffee"),
                Product(name = "Filter Coffee", price = 20.0, category = "Tea & Coffee"),
                Product(name = "Green Tea", price = 25.0, category = "Tea & Coffee"),
                Product(name = "Crispy Samosa", price = 20.0, category = "Snacks"),
                Product(name = "Vada Pav", price = 25.0, category = "Snacks"),
                Product(name = "Bun Maska", price = 30.0, category = "Snacks"),
                Product(name = "Cheese Sandwich", price = 50.0, category = "Snacks"),
                Product(name = "Osmania Biscuits (2 pcs)", price = 10.0, category = "Bakery"),
                Product(name = "Bread Omelette", price = 40.0, category = "Snacks"),
                Product(name = "Lemon Honey Tea", price = 20.0, category = "Tea & Coffee")
            )
            productDao.insertProducts(initialProducts)
        }
    }
}
