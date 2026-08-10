package com.example.printer

object EscPosCommands {
    val INIT = byteArrayOf(0x1B, 0x40)
    val ALIGN_LEFT = byteArrayOf(0x1B, 0x61, 0x00)
    val ALIGN_CENTER = byteArrayOf(0x1B, 0x61, 0x01)
    val ALIGN_RIGHT = byteArrayOf(0x1B, 0x61, 0x02)
    val BOLD_ON = byteArrayOf(0x1B, 0x45, 0x01)
    val BOLD_OFF = byteArrayOf(0x1B, 0x45, 0x00)
    val DOUBLE_SIZE = byteArrayOf(0x1D, 0x21, 0x11)
    val NORMAL_SIZE = byteArrayOf(0x1D, 0x21, 0x00)
    val FEED_LINE = byteArrayOf(0x0A)
    val FEED_3_LINES = byteArrayOf(0x1B, 0x64, 0x03)
    val CUT_PAPER = byteArrayOf(0x1D, 0x56, 0x41, 0x00)

    fun formatTwoColumns(left: String, right: String, totalWidth: Int = 32): String {
        val available = totalWidth - right.length
        val leftTrimmed = if (left.length > available - 1) left.take(available - 1) else left
        val spaces = (totalWidth - leftTrimmed.length - right.length).coerceAtLeast(1)
        return leftTrimmed + " ".repeat(spaces) + right
    }

    fun formatThreeColumns(col1: String, col2: String, col3: String, totalWidth: Int = 32): String {
        // e.g. "Masala Chai x2      Rs 30"
        val leftPart = "$col1 x$col2"
        return formatTwoColumns(leftPart, col3, totalWidth)
    }

    fun divider(char: Char = '-', totalWidth: Int = 32): String {
        return char.toString().repeat(totalWidth)
    }
}
