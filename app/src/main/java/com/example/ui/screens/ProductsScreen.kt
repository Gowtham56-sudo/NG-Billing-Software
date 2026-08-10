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
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.Product
import com.example.ui.theme.*
import com.example.viewmodel.ActiveDialog
import com.example.viewmodel.BillingViewModel
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductsScreen(viewModel: BillingViewModel) {
    val rawProducts by viewModel.rawProducts.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()

    var productToDelete by remember { mutableStateOf<Product?>(null) }

    val filteredProducts = remember(rawProducts, searchQuery) {
        if (searchQuery.isBlank()) rawProducts
        else rawProducts.filter { it.name.contains(searchQuery, ignoreCase = true) }
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = { viewModel.showDialog(ActiveDialog.AddProduct) },
                containerColor = AmberPrimary,
                contentColor = Color.White,
                modifier = Modifier.testTag("add_product_fab")
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Product")
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(WarmBackground)
        ) {
            // Header
            Surface(
                color = WarmSurface,
                tonalElevation = 2.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Product Management",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = DarkCharcoal
                    )
                    Text(
                        text = "Total ${rawProducts.size} items in menu",
                        style = MaterialTheme.typography.bodySmall,
                        color = SubtitleGray
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { viewModel.setSearchQuery(it) },
                        placeholder = { Text("Filter products by name...", color = SubtitleGray) },
                        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = AmberPrimary) },
                        trailingIcon = if (searchQuery.isNotEmpty()) {
                            {
                                IconButton(onClick = { viewModel.setSearchQuery("") }) {
                                    Icon(Icons.Default.Clear, contentDescription = "Clear", tint = DarkCharcoal)
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
                            focusedContainerColor = WarmBackground,
                            unfocusedContainerColor = WarmBackground,
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
                            .fillMaxWidth()
                            .testTag("search_product_management")
                    )
                }
            }

            // Products List
            if (filteredProducts.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Fastfood,
                            contentDescription = null,
                            modifier = Modifier.size(60.dp),
                            tint = SubtitleGray.copy(alpha = 0.5f)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = if (rawProducts.isEmpty()) "No menu items added yet" else "No matching products",
                            style = MaterialTheme.typography.titleMedium,
                            color = SubtitleGray
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Button(
                            onClick = { viewModel.showDialog(ActiveDialog.AddProduct) },
                            colors = ButtonDefaults.buttonColors(containerColor = AmberPrimary)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Add First Product")
                        }
                    }
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(top = 12.dp, bottom = 80.dp, start = 16.dp, end = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(filteredProducts, key = { it.id }) { product ->
                        ProductItemCard(
                            product = product,
                            onEdit = { viewModel.showDialog(ActiveDialog.EditProduct(product)) },
                            onDelete = { productToDelete = product }
                        )
                    }
                }
            }
        }
    }

    // Delete Confirmation Dialog
    productToDelete?.let { prod ->
        AlertDialog(
            onDismissRequest = { productToDelete = null },
            title = { Text("Delete Product?") },
            text = { Text("Are you sure you want to remove '${prod.name}' (Rs ${prod.price}) from your tea shop menu?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteProduct(prod)
                        productToDelete = null
                    },
                    modifier = Modifier.testTag("confirm_delete_product_btn")
                ) {
                    Text("Delete", color = SoftRed, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { productToDelete = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun ProductItemCard(
    product: Product,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .clickable { onEdit() }
            .testTag("product_management_card_${product.id}"),
        colors = CardDefaults.cardColors(containerColor = WarmSurface),
        border = BorderStroke(1.dp, BorderGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Thumbnail icon
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .background(AmberPrimary.copy(alpha = 0.12f), shape = RoundedCornerShape(10.dp)),
                contentAlignment = Alignment.Center
            ) {
                val icon = when (product.category.lowercase()) {
                    "tea & coffee" -> Icons.Default.LocalCafe
                    "snacks" -> Icons.Default.Fastfood
                    "bakery" -> Icons.Default.BakeryDining
                    else -> Icons.Default.Restaurant
                }
                Icon(icon, contentDescription = null, tint = AmberPrimary, modifier = Modifier.size(24.dp))
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = product.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = DarkCharcoal,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = WarmSurfaceVariant
                    ) {
                        Text(
                            text = product.category,
                            style = MaterialTheme.typography.labelSmall,
                            color = SubtitleGray,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                    Text(
                        text = "Rs ${String.format(Locale.US, "%.2f", product.price)}",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = OrangeAccent
                    )
                }
            }

            IconButton(
                onClick = onEdit,
                modifier = Modifier.testTag("edit_product_btn_${product.id}")
            ) {
                Icon(Icons.Default.Edit, contentDescription = "Edit", tint = AmberDark)
            }

            IconButton(
                onClick = onDelete,
                modifier = Modifier.testTag("delete_product_btn_${product.id}")
            ) {
                Icon(Icons.Default.DeleteOutline, contentDescription = "Delete", tint = SoftRed)
            }
        }
    }
}
