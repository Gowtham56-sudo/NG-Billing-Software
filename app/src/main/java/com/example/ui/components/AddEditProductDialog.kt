package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BakeryDining
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Coffee
import androidx.compose.material.icons.filled.Fastfood
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.example.data.Product
import com.example.ui.theme.AmberPrimary
import com.example.ui.theme.TerracottaDark

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AddEditProductDialog(
    editingProduct: Product? = null,
    categories: List<String>,
    onDismiss: () -> Unit,
    onSave: (name: String, price: Double, category: String, imagePath: String?) -> Unit
) {
    var name by remember { mutableStateOf(editingProduct?.name ?: "") }
    var priceText by remember { mutableStateOf(editingProduct?.price?.let { if (it % 1 == 0.0) it.toInt().toString() else it.toString() } ?: "") }
    var selectedCategory by remember { mutableStateOf(editingProduct?.category ?: "Tea & Coffee") }
    var nameError by remember { mutableStateOf(false) }
    var priceError by remember { mutableStateOf(false) }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .clip(RoundedCornerShape(20.dp))
                .testTag("add_edit_product_dialog"),
            color = MaterialTheme.colorScheme.surface,
            tonalElevation = 8.dp
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (editingProduct == null) "Add New Product" else "Edit Product",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier.testTag("close_add_product_btn")
                    ) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Product Name Field
                OutlinedTextField(
                    value = name,
                    onValueChange = {
                        name = it
                        nameError = false
                    },
                    label = { Text("Product Name *") },
                    placeholder = { Text("e.g. Masala Chai, Samosa") },
                    isError = nameError,
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("product_name_input")
                )
                if (nameError) {
                    Text(
                        text = "Please enter product name",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(start = 4.dp, top = 2.dp)
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Product Price Field
                OutlinedTextField(
                    value = priceText,
                    onValueChange = {
                        priceText = it
                        priceError = false
                    },
                    label = { Text("Price (Rs) *") },
                    placeholder = { Text("15.00") },
                    leadingIcon = { Text("Rs ", fontWeight = FontWeight.Bold) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    isError = priceError,
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("product_price_input")
                )
                if (priceError) {
                    Text(
                        text = "Please enter a valid price",
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(start = 4.dp, top = 2.dp)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Category Selection
                Text(
                    text = "Category",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(8.dp))

                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val availableCategories = categories.filterNot { it == "All" }
                    availableCategories.forEach { cat ->
                        val isSelected = selectedCategory.equals(cat, ignoreCase = true)
                        FilterChip(
                            selected = isSelected,
                            onClick = { selectedCategory = cat },
                            label = { Text(cat) },
                            leadingIcon = if (isSelected) {
                                { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
                            } else null,
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = AmberPrimary,
                                selectedLabelColor = Color.White
                            ),
                            modifier = Modifier.testTag("category_chip_$cat")
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Submit Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.testTag("cancel_product_btn")
                    ) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = {
                            val trimmedName = name.trim()
                            val priceVal = priceText.toDoubleOrNull()
                            if (trimmedName.isEmpty()) {
                                nameError = true
                                return@Button
                            }
                            if (priceVal == null || priceVal <= 0.0) {
                                priceError = true
                                return@Button
                            }
                            onSave(trimmedName, priceVal, selectedCategory, null)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AmberPrimary),
                        modifier = Modifier.testTag("save_product_btn")
                    ) {
                        Text(if (editingProduct == null) "Save Product" else "Update Product")
                    }
                }
            }
        }
    }
}
