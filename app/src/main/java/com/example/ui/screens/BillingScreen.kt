package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.Product
import com.example.printer.PrinterConnectionStatus
import com.example.ui.theme.*
import com.example.viewmodel.BillingViewModel
import com.example.viewmodel.CartItem
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BillingScreen(
    viewModel: BillingViewModel,
    onNavigateToPrinterSetup: () -> Unit
) {
    val filteredProducts by viewModel.filteredProducts.collectAsState()
    val cartItems by viewModel.cartItems.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    val printerStatus by viewModel.printerManager.connectionStatus.collectAsState()
    val connectedDeviceName by viewModel.printerManager.connectedDeviceName.collectAsState()
    val shopName by viewModel.shopName.collectAsState()
    val paymentMode by viewModel.paymentMode.collectAsState()
    val discountPercent by viewModel.discountPercent.collectAsState()
    val isPrinting by viewModel.isPrinting.collectAsState()

    var isCartBottomSheetOpen by remember { mutableStateOf(false) }

    val subtotal = viewModel.subtotal
    val grandTotal = viewModel.grandTotal
    val totalCount = viewModel.totalItemCount

    Scaffold(
        floatingActionButton = {
            if (cartItems.isNotEmpty()) {
                ExtendedFloatingActionButton(
                    onClick = { isCartBottomSheetOpen = true },
                    containerColor = AmberPrimary,
                    contentColor = Color.White,
                    icon = {
                        BadgedBox(
                            badge = {
                                Badge(containerColor = TerracottaDark, contentColor = Color.White) {
                                    Text(totalCount.toString())
                                }
                            }
                        ) {
                            Icon(Icons.Default.ReceiptLong, contentDescription = "Current Cart")
                        }
                    },
                    text = {
                        Text(
                            text = "View Cart (Rs ${String.format(Locale.US, "%.0f", grandTotal)})",
                            fontWeight = FontWeight.Bold
                        )
                    },
                    modifier = Modifier.testTag("floating_cart_fab")
                )
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(WarmBackground)
        ) {
            // Shop Header Banner & Printer Status Pill
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp),
                colors = CardDefaults.cardColors(containerColor = WarmSurface),
                border = BorderStroke(1.dp, BorderGray),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                shape = RoundedCornerShape(20.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.LocalCafe,
                                contentDescription = null,
                                tint = AmberPrimary,
                                modifier = Modifier.size(22.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = shopName,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = DarkCharcoal,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(top = 2.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .background(
                                        when (printerStatus) {
                                            PrinterConnectionStatus.CONNECTED -> MintGreen
                                            PrinterConnectionStatus.CONNECTING -> AmberPrimary
                                            else -> SoftRed
                                        },
                                        shape = CircleShape
                                    )
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> "THERMAL PRINTER CONNECTED"
                                    PrinterConnectionStatus.CONNECTING -> "CONNECTING PRINTER..."
                                    else -> "PRINTER DISCONNECTED"
                                },
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> MintGreen
                                    PrinterConnectionStatus.CONNECTING -> AmberPrimary
                                    else -> SoftRed
                                }
                            )
                        }
                    }

                    // Printer Status Pill Button
                    Surface(
                        onClick = onNavigateToPrinterSetup,
                        shape = RoundedCornerShape(50.dp),
                        color = when (printerStatus) {
                            PrinterConnectionStatus.CONNECTED -> Color(0xFFDCFCE7)
                            PrinterConnectionStatus.CONNECTING -> LavenderContainer
                            else -> Color(0xFFFEE2E2)
                        },
                        modifier = Modifier.testTag("printer_status_pill")
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> Icons.Default.Print
                                    PrinterConnectionStatus.CONNECTING -> Icons.Default.Sync
                                    else -> Icons.Default.PrintDisabled
                                },
                                contentDescription = "Printer Status",
                                tint = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> MintGreen
                                    PrinterConnectionStatus.CONNECTING -> AmberPrimary
                                    else -> SoftRed
                                },
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> "Ready"
                                    PrinterConnectionStatus.CONNECTING -> "Syncing"
                                    else -> "Setup"
                                },
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = when (printerStatus) {
                                    PrinterConnectionStatus.CONNECTED -> MintGreen
                                    PrinterConnectionStatus.CONNECTING -> AmberPrimary
                                    else -> SoftRed
                                }
                            )
                        }
                    }
                }
            }

            // Search Bar & Filter Row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { viewModel.setSearchQuery(it) },
                    placeholder = { Text("Search tea, coffee, samosa...", color = SubtitleGray) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = AmberPrimary) },
                    trailingIcon = if (searchQuery.isNotEmpty()) {
                        {
                            IconButton(onClick = { viewModel.setSearchQuery("") }) {
                                Icon(Icons.Default.Clear, contentDescription = "Clear search", tint = DarkCharcoal)
                            }
                        }
                    } else null,
                    singleLine = true,
                    shape = RoundedCornerShape(16.dp),
                    textStyle = TextStyle(
                        color = DarkCharcoal,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold
                    ),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = DarkCharcoal,
                        unfocusedTextColor = DarkCharcoal,
                        focusedContainerColor = WarmSurface,
                        unfocusedContainerColor = WarmSurface,
                        focusedBorderColor = AmberPrimary,
                        unfocusedBorderColor = BorderGray,
                        focusedLeadingIconColor = AmberPrimary,
                        unfocusedLeadingIconColor = SubtitleGray,
                        focusedTrailingIconColor = DarkCharcoal,
                        unfocusedTrailingIconColor = SubtitleGray,
                        focusedPlaceholderColor = SubtitleGray,
                        unfocusedPlaceholderColor = SubtitleGray
                    ),
                    modifier = Modifier
                        .weight(1f)
                        .testTag("search_products_input")
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Category Horizontal Tabs
            LazyRow(
                contentPadding = PaddingValues(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(viewModel.categories) { category ->
                    val isSelected = selectedCategory.equals(category, ignoreCase = true)
                    FilterChip(
                        selected = isSelected,
                        onClick = { viewModel.setSelectedCategory(category) },
                        label = { Text(category, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium) },
                        leadingIcon = {
                            val icon = when (category.lowercase()) {
                                "tea & coffee" -> Icons.Default.LocalCafe
                                "snacks" -> Icons.Default.Fastfood
                                "bakery" -> Icons.Default.BakeryDining
                                else -> Icons.Default.RestaurantMenu
                            }
                            Icon(icon, contentDescription = null, modifier = Modifier.size(16.dp))
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = AmberPrimary,
                            selectedLabelColor = Color.White,
                            selectedLeadingIconColor = Color.White
                        ),
                        modifier = Modifier.testTag("filter_chip_$category")
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Product Grid Area
            if (filteredProducts.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.FreeBreakfast,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = SubtitleGray.copy(alpha = 0.5f)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "No products found",
                            style = MaterialTheme.typography.titleMedium,
                            color = SubtitleGray
                        )
                        Text(
                            text = "Try a different search or add items in Products tab",
                            style = MaterialTheme.typography.bodySmall,
                            color = SubtitleGray.copy(alpha = 0.8f)
                        )
                    }
                }
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(minSize = 140.dp),
                    contentPadding = PaddingValues(start = 12.dp, end = 12.dp, top = 4.dp, bottom = 90.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(filteredProducts, key = { it.id }) { product ->
                        val cartItem = cartItems.find { it.product.id == product.id }
                        val qtyInCart = cartItem?.quantity ?: 0

                        ProductGridCard(
                            product = product,
                            quantityInCart = qtyInCart,
                            onAddToCart = { viewModel.addToCart(product) },
                            onDecrement = { viewModel.decrementQuantity(product) }
                        )
                    }
                }
            }
        }
    }

    // Cart Sheet / Drawer Dialog for fast checkout
    if (isCartBottomSheetOpen) {
        ModalBottomSheet(
            onDismissRequest = { isCartBottomSheetOpen = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            shape = RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp),
            containerColor = WarmSurface
        ) {
            CartBottomSheetContent(
                cartItems = cartItems,
                subtotal = subtotal,
                discountPercent = discountPercent,
                grandTotal = grandTotal,
                paymentMode = paymentMode,
                isPrinting = isPrinting,
                onIncrement = { viewModel.addToCart(it.product) },
                onDecrement = { viewModel.decrementQuantity(it.product) },
                onRemove = { viewModel.removeFromCart(it.product) },
                onClearCart = { viewModel.clearCart() },
                onSetPaymentMode = { viewModel.setPaymentMode(it) },
                onSetDiscount = { viewModel.setDiscountPercent(it) },
                onPrintAndCheckout = {
                    isCartBottomSheetOpen = false
                    viewModel.processAndPrintBill()
                }
            )
        }
    }
}

@Composable
fun ProductGridCard(
    product: Product,
    quantityInCart: Int,
    onAddToCart: () -> Unit,
    onDecrement: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .clickable { onAddToCart() }
            .testTag("product_card_${product.id}"),
        colors = CardDefaults.cardColors(
            containerColor = WarmSurfaceVariant
        ),
        border = if (quantityInCart > 0) BorderStroke(2.dp, AmberPrimary) else BorderStroke(1.dp, BorderGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            // Category Icon Badge & Quantity Indicator
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .background(LavenderContainer, shape = RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    val icon = when (product.category.lowercase()) {
                        "tea & coffee" -> Icons.Default.LocalCafe
                        "snacks" -> Icons.Default.Fastfood
                        "bakery" -> Icons.Default.BakeryDining
                        else -> Icons.Default.Restaurant
                    }
                    Icon(icon, contentDescription = null, tint = AmberPrimary, modifier = Modifier.size(22.dp))
                }

                if (quantityInCart > 0) {
                    Surface(
                        shape = RoundedCornerShape(50.dp),
                        color = AmberPrimary,
                        contentColor = Color.White
                    ) {
                        Text(
                            text = "×$quantityInCart",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = product.name,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = DarkCharcoal,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = "Rs ${String.format(Locale.US, "%.0f", product.price)}",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.ExtraBold,
                color = OrangeAccent
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Action Buttons
            if (quantityInCart > 0) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = onDecrement,
                        modifier = Modifier
                            .size(30.dp)
                            .background(Color.White, CircleShape)
                            .border(1.dp, AmberPrimary, CircleShape)
                            .testTag("decrement_btn_${product.id}")
                    ) {
                        Icon(Icons.Default.Remove, contentDescription = "Decrease", tint = AmberPrimary, modifier = Modifier.size(16.dp))
                    }

                    Text(
                        text = "$quantityInCart",
                        fontWeight = FontWeight.Bold,
                        color = DarkCharcoal
                    )

                    IconButton(
                        onClick = onAddToCart,
                        modifier = Modifier
                            .size(30.dp)
                            .background(AmberPrimary, CircleShape)
                            .testTag("increment_btn_${product.id}")
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "Increase", tint = Color.White, modifier = Modifier.size(16.dp))
                    }
                }
            } else {
                Button(
                    onClick = onAddToCart,
                    colors = ButtonDefaults.buttonColors(containerColor = AmberPrimary),
                    contentPadding = PaddingValues(vertical = 4.dp),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(34.dp)
                        .testTag("add_to_cart_btn_${product.id}")
                ) {
                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Add", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun CartBottomSheetContent(
    cartItems: List<CartItem>,
    subtotal: Double,
    discountPercent: Double,
    grandTotal: Double,
    paymentMode: String,
    isPrinting: Boolean,
    onIncrement: (CartItem) -> Unit,
    onDecrement: (CartItem) -> Unit,
    onRemove: (CartItem) -> Unit,
    onClearCart: () -> Unit,
    onSetPaymentMode: (String) -> Unit,
    onSetDiscount: (Double) -> Unit,
    onPrintAndCheckout: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 10.dp)
            .testTag("cart_bottom_sheet")
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Current Bill",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            if (cartItems.isNotEmpty()) {
                TextButton(
                    onClick = onClearCart,
                    modifier = Modifier.testTag("clear_cart_btn")
                ) {
                    Icon(Icons.Default.DeleteOutline, contentDescription = null, tint = SoftRed, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Clear All", color = SoftRed)
                }
            }
        }

        Divider(modifier = Modifier.padding(vertical = 8.dp))

        if (cartItems.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp),
                contentAlignment = Alignment.Center
            ) {
                Text("Your bill cart is empty", color = SubtitleGray)
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 240.dp)
            ) {
                cartItems.forEach { item ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = item.product.name,
                                fontWeight = FontWeight.SemiBold,
                                color = DarkCharcoal,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                            Text(
                                text = "Rs ${item.product.price} x ${item.quantity}",
                                style = MaterialTheme.typography.bodySmall,
                                color = SubtitleGray
                            )
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            IconButton(
                                onClick = { onDecrement(item) },
                                modifier = Modifier.size(28.dp)
                            ) {
                                Icon(Icons.Default.Remove, contentDescription = "Minus", modifier = Modifier.size(16.dp))
                            }
                            Text(
                                text = "${item.quantity}",
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(horizontal = 8.dp)
                            )
                            IconButton(
                                onClick = { onIncrement(item) },
                                modifier = Modifier.size(28.dp)
                            ) {
                                Icon(Icons.Default.Add, contentDescription = "Plus", modifier = Modifier.size(16.dp))
                            }
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Rs ${String.format(Locale.US, "%.0f", item.product.price * item.quantity)}",
                                fontWeight = FontWeight.Bold,
                                color = TerracottaDark
                            )
                        }
                    }
                    Divider(color = Color(0xFFF3F4F6))
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Payment Mode Selector
            Text("Payment Method", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(6.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf("Cash", "UPI / QR", "Card").forEach { mode ->
                    val isSelected = paymentMode.equals(mode, ignoreCase = true)
                    FilterChip(
                        selected = isSelected,
                        onClick = { onSetPaymentMode(mode) },
                        label = { Text(mode) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = AmberPrimary,
                            selectedLabelColor = Color.White
                        ),
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Summary Totals
            Card(
                colors = CardDefaults.cardColors(containerColor = WarmSurfaceVariant),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Subtotal", color = SubtitleGray)
                        Text("Rs ${String.format(Locale.US, "%.2f", subtotal)}", fontWeight = FontWeight.Medium)
                    }
                    if (discountPercent > 0) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Discount ($discountPercent%)", color = MintGreen)
                            Text("- Rs ${String.format(Locale.US, "%.2f", subtotal * (discountPercent / 100.0))}", color = MintGreen)
                        }
                    }
                    Divider(modifier = Modifier.padding(vertical = 6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("GRAND TOTAL", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                        Text(
                            "Rs ${String.format(Locale.US, "%.2f", grandTotal)}",
                            fontWeight = FontWeight.ExtraBold,
                            style = MaterialTheme.typography.titleLarge,
                            color = OrangeAccent
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Print & Checkout Button
            Button(
                onClick = onPrintAndCheckout,
                enabled = !isPrinting,
                colors = ButtonDefaults.buttonColors(containerColor = AmberPrimary),
                shape = RoundedCornerShape(50.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp)
                    .testTag("print_bill_and_checkout_btn")
            ) {
                if (isPrinting) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Printing Receipt...")
                } else {
                    Icon(Icons.Default.Print, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "PRINT BILL & CHECKOUT (Rs ${String.format(Locale.US, "%.0f", grandTotal)})",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
        }
    }
}
