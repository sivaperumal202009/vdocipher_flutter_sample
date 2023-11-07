import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vdocipher_flutter_v3/helpers/color_resource.dart';
import 'package:vdocipher_flutter_v3/helpers/font.dart';

class CustomText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final String font;
  final Color color;
  final double lineHeight;
  final TextAlign textAlign;
  final bool isUnderLine;
  final bool isSingleLine;
  final int? maxLines;
  final bool isSelectableText;
  final String? copyText;
  final bool isLineThrough;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  const CustomText(
    this.text, {
    this.fontSize = 14,
    this.font = Font.nunitoSans,
    this.color = ColorResource.color000000,
    this.lineHeight = 1.21,
    this.textAlign = TextAlign.left,
    this.isUnderLine = false,
    this.isSingleLine = false,
    this.maxLines,
    this.isSelectableText = false,
    this.isLineThrough = false,
    this.copyText,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Text textWidget = Text(
      text ?? "",
      textAlign: textAlign,
      overflow: isSingleLine ? TextOverflow.ellipsis : null,
      softWrap: true,
      maxLines: maxLines,
      style: GoogleFonts.getFont(
        font,
        textStyle: TextStyle(
          decoration: isLineThrough
              ? TextDecoration.lineThrough
              : isUnderLine
                  ? TextDecoration.underline
                  : TextDecoration.none,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          fontSize: fontSize,
          height: lineHeight,
        ),
      ),
    );

    final SelectableText selectableText = SelectableText(
      text ?? "",
      textAlign: textAlign,
      showCursor: true,
      maxLines: maxLines,
      style: GoogleFonts.getFont(
        font,
        textStyle: TextStyle(
          decoration: isLineThrough
              ? TextDecoration.lineThrough
              : isUnderLine
                  ? TextDecoration.underline
                  : TextDecoration.none,
          color: color,
          fontSize: fontSize,
          height: lineHeight,
        ),
      ),
    );

    return isSelectableText ? selectableText : textWidget;
  }
}
