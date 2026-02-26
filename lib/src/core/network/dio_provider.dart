import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';

final authDioProvider = Provider<Dio>((_) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstants.authBaseUrl,
      connectTimeout: ApiConstants.requestTimeout,
      receiveTimeout: ApiConstants.requestTimeout,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ApiConstants.reqResApiKey,
      },
    ),
  );
});

final tasksDioProvider = Provider<Dio>((_) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstants.tasksBaseUrl,
      connectTimeout: ApiConstants.requestTimeout,
      receiveTimeout: ApiConstants.requestTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );
});
