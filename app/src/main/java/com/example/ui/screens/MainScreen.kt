package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.PointOfSale
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.RestaurantMenu
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ui.components.AddEditProductDialog
import com.example.ui.components.ReceiptDialog
import com.example.ui.theme.*
import com.example.viewmodel.ActiveDialog
import com.example.viewmodel.BillingViewModel

enum class NavigationTab(val title: String, val icon: ImageVector) {
    BILLING("Billing", Icons.Default.PointOfSale),
    PRODUCTS("Products", Icons.Default.RestaurantMenu),
    PRINTER("Printer Setup", Icons.Default.Print),
    HISTORY("History", Icons.Default.History)
}

@Composable
fun MainScreen(viewModel: BillingViewModel = viewModel()) {
    var selectedTab by remember { mutableStateOf(NavigationTab.BILLING) }

    val activeDialog by viewModel.activeDialog.collectAsState()
    val toastMessage by viewModel.toastMessage.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(toastMessage) {
        toastMessage?.let { msg ->
            snackbarHostState.showSnackbar(msg)
            viewModel.clearToast()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            NavigationBar(
                containerColor = WarmSurfaceVariant,
                tonalElevation = 2.dp,
                modifier = Modifier
                    .windowInsetsPadding(WindowInsets.navigationBars)
                    .testTag("bottom_navigation_bar")
            ) {
                NavigationTab.entries.forEach { tab ->
                    val isSelected = selectedTab == tab
                    NavigationBarItem(
                        selected = isSelected,
                        onClick = { selectedTab = tab },
                        icon = {
                            Icon(
                                imageVector = tab.icon,
                                contentDescription = tab.title
                            )
                        },
                        label = {
                            Text(
                                text = tab.title,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = TerracottaDark,
                            selectedTextColor = TerracottaDark,
                            indicatorColor = LavenderContainer,
                            unselectedIconColor = SubtitleGray,
                            unselectedTextColor = SubtitleGray
                        ),
                        modifier = Modifier.testTag("nav_tab_${tab.name.lowercase()}")
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(WarmBackground)
        ) {
            when (selectedTab) {
                NavigationTab.BILLING -> BillingScreen(
                    viewModel = viewModel,
                    onNavigateToPrinterSetup = { selectedTab = NavigationTab.PRINTER }
                )
                NavigationTab.PRODUCTS -> ProductsScreen(viewModel = viewModel)
                NavigationTab.PRINTER -> PrinterSetupScreen(viewModel = viewModel)
                NavigationTab.HISTORY -> BillHistoryScreen(viewModel = viewModel)
            }
        }
    }

    // Dialog overlays
    when (val dialog = activeDialog) {
        is ActiveDialog.AddProduct -> {
            AddEditProductDialog(
                editingProduct = null,
                categories = viewModel.categories,
                onDismiss = { viewModel.dismissDialog() },
                onSave = { name, price, category, imagePath ->
                    viewModel.addProduct(name, price, category, imagePath)
                }
            )
        }
        is ActiveDialog.EditProduct -> {
            AddEditProductDialog(
                editingProduct = dialog.product,
                categories = viewModel.categories,
                onDismiss = { viewModel.dismissDialog() },
                onSave = { name, price, category, imagePath ->
                    viewModel.updateProduct(dialog.product.copy(name = name, price = price, category = category, imagePath = imagePath))
                }
            )
        }
        is ActiveDialog.ReceiptPreview -> {
            ReceiptDialog(
                receiptText = dialog.receiptText,
                isTestPrint = dialog.isTestPrint,
                onDismiss = { viewModel.dismissDialog() },
                onPrintAgain = {
                    if (dialog.isTestPrint) {
                        viewModel.doTestPrint()
                    } else {
                        viewModel.processAndPrintBill()
                    }
                }
            )
        }
        null -> {}
        else -> {}
    }
}
