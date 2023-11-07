import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vdocipher_flutter_v3/helpers/app_utils.dart';
import 'package:vdocipher_flutter_v3/helpers/string_constants.dart';

class DioHelper {
  Dio dio = Dio();

  DioHelper() {
    _init();
  }

  void _init() {
    dio = Dio();
    dio.options.followRedirects = true;
    dio.options.headers[HttpHeaders.acceptHeader] = "application/json";
    dio.options.connectTimeout = const Duration(milliseconds: 30000);
    dio.options.validateStatus = (status) => status! <= 400;
    dio.transformer = BackgroundTransformer();
    //setup auth interceptor
    _setupAuthInterceptor();
    //setup log interceptor
    _setupLogInterceptor();
  }

  void _setupAuthInterceptor() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (
          DioException error,
          ErrorInterceptorHandler errorInterceptorHandler,
        ) async {
          if (error.message?.contains("SocketException") ?? false) {
            errorInterceptorHandler.resolve(
              Response(
                requestOptions: error.requestOptions,
                data: {"error": StringConstants.checkYourInternetError},
                statusCode: error.response?.statusCode,
              ),
            );
          } else {
            errorInterceptorHandler.resolve(
              Response(
                requestOptions: error.requestOptions,
                data: {"error": error.message},
                statusCode: error.response?.statusCode,
              ),
            );
          }
        },
      ),
    );
  }

  void _setupLogInterceptor() {
    if (DebugMode.isInDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          requestBody: true,
        ),
      );
    }
  }
}

final Dio dio = DioHelper().dio;
