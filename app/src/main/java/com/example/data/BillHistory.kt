package com.example.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "bill_history")
data class BillHistory(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val billNumber: String,
    val itemsJson: String,
    val subtotal: Double,
    val tax: Double = 0.0,
    val discount: Double = 0.0,
    val total: Double,
    val paymentMode: String = "Cash",
    val timestamp: Long = System.currentTimeMillis()
)
