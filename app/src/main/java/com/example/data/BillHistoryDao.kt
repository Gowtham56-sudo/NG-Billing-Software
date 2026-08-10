package com.example.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface BillHistoryDao {
    @Query("SELECT * FROM bill_history ORDER BY timestamp DESC")
    fun getAllBills(): Flow<List<BillHistory>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBill(bill: BillHistory): Long

    @Query("SELECT * FROM bill_history WHERE id = :id")
    suspend fun getBillById(id: Int): BillHistory?

    @Query("DELETE FROM bill_history WHERE id = :id")
    suspend fun deleteBillById(id: Int)

    @Query("DELETE FROM bill_history")
    suspend fun clearHistory()
}
