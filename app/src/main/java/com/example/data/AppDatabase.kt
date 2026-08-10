package com.example.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Database(entities = [Product::class, BillHistory::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {

    abstract fun productDao(): ProductDao
    abstract fun billHistoryDao(): BillHistoryDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "tea_billing_database"
                )
                .addCallback(DatabaseCallback())
                .build()
                INSTANCE = instance
                instance
            }
        }

        private class DatabaseCallback : RoomDatabase.Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        populateInitialProducts(database.productDao())
                    }
                }
            }

            suspend fun populateInitialProducts(productDao: ProductDao) {
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
    }
}
