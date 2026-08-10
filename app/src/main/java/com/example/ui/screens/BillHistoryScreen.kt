package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.BillHistory
import com.example.ui.theme.*
import com.example.viewmodel.ActiveDialog
import com.example.viewmodel.BillingViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BillHistoryScreen(viewModel: BillingViewModel) {
    val billHistory by viewModel.billHistory.collectAsState()
    val shopName by viewModel.shopName.collectAsState()

    var billToDelete by remember { mutableStateOf<BillHistory?>(null) }

    val totalRevenue = remember(billHistory) { billHistory.sumOf { it.total } }
    val totalBills = billHistory.size

    val dateFormat = remember { SimpleDateFormat("dd MMM, hh:mm a", Locale.getDefault()) }

    Scaffold { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(WarmBackground)
        ) {
            // Header Title & Daily Revenue Card
            Surface(
                color = WarmSurface,
                tonalElevation = 2.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Bill History & Sales",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = DarkCharcoal
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    // Daily Sales Summary Card
                    Card(
                        colors = CardDefaults.cardColors(containerColor = WarmSurfaceVariant),
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("Total Sales Revenue", style = MaterialTheme.typography.bodySmall, color = SubtitleGray)
                                Text(
                                    text = "Rs ${String.format(Locale.US, "%.2f", totalRevenue)}",
                                    style = MaterialTheme.typography.headlineMedium,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = OrangeAccent
                                )
                            }

                            Column(horizontalAlignment = Alignment.End) {
                                Text("Bills Generated", style = MaterialTheme.typography.bodySmall, color = SubtitleGray)
                                Text(
                                    text = "$totalBills Bills",
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = DarkCharcoal
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Bills List
            if (billHistory.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.ReceiptLong,
                            contentDescription = null,
                            modifier = Modifier.size(60.dp),
                            tint = SubtitleGray.copy(alpha = 0.5f)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "No past bills created yet",
                            style = MaterialTheme.typography.titleMedium,
                            color = SubtitleGray
                        )
                        Text(
                            text = "Bills you generate in Billing screen will appear here",
                            style = MaterialTheme.typography.bodySmall,
                            color = SubtitleGray.copy(alpha = 0.8f)
                        )
                    }
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 80.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(billHistory, key = { it.id }) { bill ->
                        BillHistoryCard(
                            bill = bill,
                            dateString = dateFormat.format(Date(bill.timestamp)),
                            onViewReceipt = {
                                val text = buildReceiptStringFromHistory(shopName, bill)
                                viewModel.showDialog(ActiveDialog.ReceiptPreview(text, isTestPrint = false))
                            },
                            onDelete = { billToDelete = bill }
                        )
                    }
                }
            }
        }
    }

    // Delete Confirmation
    billToDelete?.let { bill ->
        AlertDialog(
            onDismissRequest = { billToDelete = null },
            title = { Text("Delete Bill Record?") },
            text = { Text("Delete record for ${bill.billNumber} (Rs ${bill.total})?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteBillHistory(bill.id)
                        billToDelete = null
                    },
                    modifier = Modifier.testTag("confirm_delete_bill_btn")
                ) {
                    Text("Delete", color = SoftRed, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { billToDelete = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun BillHistoryCard(
    bill: BillHistory,
    dateString: String,
    onViewReceipt: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .clickable { onViewReceipt() }
            .testTag("bill_history_card_${bill.id}"),
        colors = CardDefaults.cardColors(containerColor = WarmSurface),
        border = BorderStroke(1.dp, BorderGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Receipt,
                        contentDescription = null,
                        tint = AmberPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = bill.billNumber,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = DarkCharcoal
                    )
                }

                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = WarmSurfaceVariant
                ) {
                    Text(
                        text = bill.paymentMode,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = SubtitleGray,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = bill.itemsJson,
                style = MaterialTheme.typography.bodyMedium,
                color = DarkCharcoal,
                maxLines = 2
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = dateString,
                    style = MaterialTheme.typography.bodySmall,
                    color = SubtitleGray
                )

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Rs ${String.format(Locale.US, "%.2f", bill.total)}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.ExtraBold,
                        color = OrangeAccent
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    IconButton(
                        onClick = onViewReceipt,
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(Icons.Default.Print, contentDescription = "Reprint Receipt", tint = AmberDark, modifier = Modifier.size(18.dp))
                    }
                    IconButton(
                        onClick = onDelete,
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(Icons.Default.DeleteOutline, contentDescription = "Delete", tint = SoftRed, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
    }
}

fun buildReceiptStringFromHistory(shopName: String, bill: BillHistory): String {
    val dateFormat = SimpleDateFormat("dd/MM/yyyy hh:mm a", Locale.getDefault())
    val dateStr = dateFormat.format(Date(bill.timestamp))

    return buildString {
        append("        $shopName\n")
        append("   Fresh Chai, Coffee & Snacks\n")
        append("================================\n")
        append("Bill No: ${bill.billNumber}\n")
        append("Date   : $dateStr\n")
        append("Payment: ${bill.paymentMode}\n")
        append("--------------------------------\n")
        append(bill.itemsJson.replace("; ", "\n"))
        append("\n--------------------------------\n")
        if (bill.discount > 0) {
            append("Discount: - Rs ${String.format(Locale.US, "%.2f", bill.discount)}\n")
        }
        append("================================\n")
        append("GRAND TOTAL: Rs ${String.format(Locale.US, "%.2f", bill.total)}\n")
        append("================================\n")
        append("   Visit Again! Have a Great Day!\n\n")
    }
}
