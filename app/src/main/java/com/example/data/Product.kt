package com.example.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "products")
data class Product(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val price: Double,
    val category: String = "Tea & Coffee",
    val imagePath: String? = null,
    val isAvailable: Boolean = true
)
