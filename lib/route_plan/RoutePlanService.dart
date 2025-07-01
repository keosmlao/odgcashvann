import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utility/my_constant.dart';

class RoutePlanService {
  static Future<Map<String, dynamic>?> getPlanDetails(String docNo) async {
    final url = '${MyConstant().domain}/getplanstillstart/$docNo';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Failed to fetch data");
  }

  static Future<bool> finishPlan({
    required String saleCode,
    required String finishDate,
    required String routeId,
  }) async {
    final url = '${MyConstant().domain}/finish_plan';
    final body = json.encode({
      'sale_code': saleCode,
      'fishis_plan': finishDate,
      'route_id': routeId,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: body,
    );

    if (response.statusCode == 200) {
      final resBody = json.decode(response.body);
      return resBody['status'] == 'complete';
    }
    return false;
  }
}
