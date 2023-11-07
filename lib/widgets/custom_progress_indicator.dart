import 'package:flutter/material.dart';
import 'package:vdocipher_flutter_v3/helpers/color_resource.dart';

class CustomProgressIndicator extends StatelessWidget {
  final bool isLinear;
  final bool isCenter;
  final Color valueColor;

  const CustomProgressIndicator({
    super.key,
    this.isLinear = false,
    this.isCenter = true,
    this.valueColor = ColorResource.color28B7E5,
  });

  @override
  Widget build(BuildContext context) {
    return isLinear ? lineraIndicator() : circularIndicator();
  }

  Widget lineraIndicator() {
    if (isCenter) {
      return const Center(
        child: LinearProgressIndicator(),
      );
    } else {
      return LinearProgressIndicator(
        value: 2,
        valueColor: AlwaysStoppedAnimation<Color>(valueColor),
      );
    }
  }

  Widget circularIndicator() {
    if (isCenter) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(valueColor),
        ),
      );
    } else {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(valueColor),
      );
    }
  }
}
