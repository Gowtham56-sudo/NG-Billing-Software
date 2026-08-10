package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Print
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.ui.theme.DarkCharcoal
import com.example.ui.theme.MintGreen
import com.example.ui.theme.WarmSurfaceVariant

@Composable
fun ReceiptDialog(
    receiptText: String,
    isTestPrint: Boolean = false,
    onDismiss: () -> Unit,
    onPrintAgain: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .clip(RoundedCornerShape(16.dp))
                .testTag("receipt_dialog"),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 8.dp
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = "Success",
                            tint = MintGreen,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (isTestPrint) "Test Print Receipt" else "Receipt Printed!",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier.testTag("close_receipt_button")
                    ) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Thermal Paper Simulation View
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 340.dp)
                        .background(Color(0xFFFAFAEE), shape = RoundedCornerShape(8.dp))
                        .border(1.dp, Color(0xFFE5E7EB), shape = RoundedCornerShape(8.dp))
                        .padding(12.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    Text(
                        text = receiptText,
                        fontFamily = FontFamily.Monospace,
                        fontSize = 12.sp,
                        color = DarkCharcoal,
                        lineHeight = 18.sp,
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.testTag("dismiss_receipt_btn")
                    ) {
                        Text("Done")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = onPrintAgain,
                        modifier = Modifier.testTag("reprint_receipt_btn")
                    ) {
                        Icon(
                            Icons.Default.Print,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Reprint")
                    }
                }
            }
        }
    }
}
