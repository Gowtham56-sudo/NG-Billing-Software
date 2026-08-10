package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
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
import com.example.printer.DiscoveredDevice
import com.example.printer.PrinterConnectionStatus
import com.example.ui.theme.*
import com.example.viewmodel.BillingViewModel

@Composable
fun PrinterSetupScreen(viewModel: BillingViewModel) {
    val printerStatus by viewModel.printerManager.connectionStatus.collectAsState()
    val connectedDeviceName by viewModel.printerManager.connectedDeviceName.collectAsState()
    val printerDevices by viewModel.printerDevices.collectAsState()
    val isPrinting by viewModel.isPrinting.collectAsState()
    val shopName by viewModel.shopName.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.scanPrinterDevices()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(WarmBackground)
            .padding(16.dp)
    ) {
        // Top Header Title
        Text(
            text = "Bluetooth Printer Setup",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = DarkCharcoal
        )
        Text(
            text = "Connect 58mm or 80mm ESC/POS wireless thermal receipt printers",
            style = MaterialTheme.typography.bodySmall,
            color = SubtitleGray
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Connection Status Banner Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("printer_connection_status_card"),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = when (printerStatus) {
                    PrinterConnectionStatus.CONNECTED -> Color(0xFFDCFCE7)
                    PrinterConnectionStatus.CONNECTING -> Color(0xFFFEF3C7)
                    else -> Color(0xFFFEE2E2)
                }
            )
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .background(
                                    when (printerStatus) {
                                        PrinterConnectionStatus.CONNECTED -> MintGreen
                                        PrinterConnectionStatus.CONNECTING -> AmberPrimary
                                        else -> SoftRed
                                    },
                                    shape = CircleShape
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> Icons.Default.Check
                                    PrinterConnectionStatus.CONNECTING -> Icons.Default.Sync
                                    else -> Icons.Default.PrintDisabled
                                },
                                contentDescription = null,
                                tint = Color.White
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                text = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> "CONNECTED ✅"
                                    PrinterConnectionStatus.CONNECTING -> "CONNECTING..."
                                    else -> "NOT CONNECTED ❌"
                                },
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleMedium,
                                color = DarkCharcoal
                            )
                            Text(
                                text = connectedDeviceName ?: "No Bluetooth printer active",
                                style = MaterialTheme.typography.bodySmall,
                                color = SubtitleGray
                            )
                        }
                    }

                    if (printerStatus == PrinterConnectionStatus.CONNECTED) {
                        OutlinedButton(
                            onClick = { viewModel.printerManager.disconnect() },
                            modifier = Modifier.testTag("disconnect_printer_btn")
                        ) {
                            Text("Disconnect")
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Test Print Button
                Button(
                    onClick = { viewModel.doTestPrint() },
                    enabled = !isPrinting,
                    colors = ButtonDefaults.buttonColors(containerColor = AmberPrimary),
                    shape = RoundedCornerShape(50.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                        .testTag("test_print_btn")
                ) {
                    if (isPrinting) {
                        CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Printing Sample...")
                    } else {
                        Icon(Icons.Default.Print, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("SEND TEST PRINT RECEIPT", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Scanner Section Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Available Bluetooth Devices",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = DarkCharcoal
            )
            ElevatedButton(
                onClick = { viewModel.scanPrinterDevices() },
                modifier = Modifier.testTag("scan_bluetooth_btn")
            ) {
                Icon(Icons.Default.BluetoothSearching, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Scan Devices")
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Devices List
        if (printerDevices.isEmpty()) {
            Card(
                colors = CardDefaults.cardColors(containerColor = WarmSurface),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(Icons.Default.Bluetooth, contentDescription = null, modifier = Modifier.size(48.dp), tint = SubtitleGray)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("No Bluetooth devices found", fontWeight = FontWeight.SemiBold, color = DarkCharcoal)
                    Text("Tap 'Scan Devices' or pair printer in phone Android Bluetooth settings", style = MaterialTheme.typography.bodySmall, color = SubtitleGray)
                }
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(printerDevices) { device ->
                    PrinterDeviceCard(
                        device = device,
                        isConnected = connectedDeviceName?.contains(device.name, ignoreCase = true) == true,
                        onConnect = { viewModel.connectPrinter(device) }
                    )
                }
            }
        }
    }
}

@Composable
fun PrinterDeviceCard(
    device: DiscoveredDevice,
    isConnected: Boolean,
    onConnect: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .clickable { onConnect() }
            .testTag("device_card_${device.macAddress}"),
        colors = CardDefaults.cardColors(
            containerColor = if (isConnected) Color(0xFFFEF3C7) else WarmSurface
        ),
        border = if (isConnected) BorderStroke(1.5.dp, AmberPrimary) else BorderStroke(0.5.dp, Color(0xFFE5E7EB))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Print,
                    contentDescription = null,
                    tint = if (isConnected) AmberPrimary else SubtitleGray,
                    modifier = Modifier.size(28.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(
                        text = device.name,
                        fontWeight = FontWeight.Bold,
                        color = DarkCharcoal
                    )
                    Text(
                        text = "MAC: ${device.macAddress} ${if (device.isPaired) "• Paired" else ""}",
                        style = MaterialTheme.typography.bodySmall,
                        color = SubtitleGray
                    )
                }
            }

            if (isConnected) {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = MintGreen,
                    contentColor = Color.White
                ) {
                    Text(
                        text = "Connected ✅",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                    )
                }
            } else {
                OutlinedButton(
                    onClick = onConnect,
                    shape = RoundedCornerShape(20.dp),
                    modifier = Modifier.testTag("connect_btn_${device.macAddress}")
                ) {
                    Text("Connect")
                }
            }
        }
    }
}
