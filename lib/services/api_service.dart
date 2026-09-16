
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl = 'http://192.168.31.70:3000';

  // ============================================================
  // CREATE CHECKOUT
  // ============================================================

  static Future<Map<String, dynamic>> createCheckout({
    required int variantId,
    required int quantity,
    required String fullName,
    required String mobile,
    required String email,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    String? landmark,
    required String city,
    required String pincode,
  }) async {
    final url = Uri.parse('$baseUrl/checkout');

    final body = {
      'variant_id': variantId,
      'quantity': quantity,
      'full_name': fullName,
      'mobile': mobile,
      'email': email,
      'house_flat_number': houseFlatNumber,
      'apartment_name': apartmentName,
      'street_area': streetArea,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to the backend server.',
      );
    }
  }

  // ============================================================
  // GET PRODUCT VARIANTS
  // ============================================================
  //
  // Backend endpoint:
  // GET /product-variants
  //
  // Used by PricingProvider to get the latest monthly rent
  // values from the backend/database.
  //
  // This keeps product pricing dynamic instead of hardcoded
  // inside the Flutter application.
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      fetchProductVariants() async {
    final url = Uri.parse('$baseUrl/product-variants');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        // Backend response:
        //
        // [
        //   {
        //     "variant_id": 1,
        //     "variant_name": "1.5 Ton",
        //     "monthly_rent": 1299
        //   }
        // ]

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        }

        // Also support:
        //
        // {
        //   "data": [
        //      {...},
        //      {...}
        //   ]
        // }

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          if (data is List) {
            return data
                .whereType<Map>()
                .map(
                  (item) => Map<String, dynamic>.from(item),
                )
                .toList();
          }

          // Also support:
          //
          // {
          //   "product_variants": [...]
          // }

          final productVariants =
              decoded['product_variants'];

          if (productVariants is List) {
            return productVariants
                .whereType<Map>()
                .map(
                  (item) => Map<String, dynamic>.from(item),
                )
                .toList();
          }

          // Also support:
          //
          // {
          //   "variants": [...]
          // }

          final variants = decoded['variants'];

          if (variants is List) {
            return variants
                .whereType<Map>()
                .map(
                  (item) => Map<String, dynamic>.from(item),
                )
                .toList();
          }
        }

        throw Exception(
          'Invalid product variants response from backend.',
        );
      }

      // ----------------------------------------------------------
      // ERROR RESPONSE
      // ----------------------------------------------------------

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final message =
              decoded['message']?.toString().trim();

          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        }
      } catch (error) {
        if (error is Exception) {
          rethrow;
        }
      }

      throw Exception(
        'Failed to load product variants. '
        'Status code: ${response.statusCode}.',
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load product variants.',
      );
    }
  }

  // ============================================================
  // GET CUSTOMER RENTALS
  // ============================================================

  static Future<Map<String, dynamic>> getCustomerRentals({
    required int customerId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/rentals/customer/$customerId',
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load customer rentals.',
      );
    }
  }

  // ============================================================
  // CREATE RAZORPAY ORDER
  // ============================================================

  static Future<Map<String, dynamic>> createPaymentOrder({
    required int orderId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/payments/create-order',
    );

    final body = {
      'order_id': orderId,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response);

      // ----------------------------------------------------------
      // GET NESTED RAZORPAY OBJECT
      // ----------------------------------------------------------

      final razorpayData = responseData['razorpay'];

      if (razorpayData is! Map) {
        throw Exception(
          'Backend did not return Razorpay order details.',
        );
      }

      final razorpayOrderId =
          razorpayData['razorpay_order_id']
              ?.toString()
              .trim();

      final amount =
          _parseInt(razorpayData['amount']);

      final currency =
          razorpayData['currency']
              ?.toString()
              .trim();

      // ----------------------------------------------------------
      // VALIDATE RAZORPAY DATA
      // ----------------------------------------------------------

      if (razorpayOrderId == null ||
          razorpayOrderId.isEmpty) {
        throw Exception(
          'Backend did not return a valid Razorpay order ID.',
        );
      }

      if (amount == null || amount <= 0) {
        throw Exception(
          'Backend did not return a valid payment amount.',
        );
      }

      if (currency == null || currency.isEmpty) {
        throw Exception(
          'Backend did not return a valid payment currency.',
        );
      }

      // ----------------------------------------------------------
      // RETURN NORMALIZED RESPONSE
      // ----------------------------------------------------------

      return {
        ...responseData,
        'razorpay_order_id': razorpayOrderId,
        'amount': amount,
        'currency': currency,
      };
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to create Razorpay payment order.',
      );
    }
  }

  // ============================================================
  // VERIFY RAZORPAY PAYMENT
  // ============================================================

  static Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = Uri.parse(
      '$baseUrl/payments/verify',
    );

    final body = {
      'order_id': orderId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to verify Razorpay payment.',
      );
    }
  }

  // ============================================================
  // GET CUSTOMER PROFILE + ADDRESS
  // ============================================================

  static Future<Map<String, dynamic>> getCustomerProfile({
    required int customerId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/customers/$customerId/profile',
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load customer profile.',
      );
    }
  }

  // ============================================================
  // UPDATE CUSTOMER PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> updateCustomer({
    required int customerId,
    required String fullName,
    required String mobile,
    required String email,
  }) async {
    final url = Uri.parse(
      '$baseUrl/customers/$customerId',
    );

    final body = {
      'full_name': fullName,
      'mobile': mobile,
      'email': email,
    };

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to update customer profile.',
      );
    }
  }

  // ============================================================
  // GET CUSTOMER ADDRESSES
  // ============================================================

  static Future<List<dynamic>> getCustomerAddresses({
    required int customerId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/addresses/customer/$customerId',
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded;
        }

        // Support { "data": [...] }
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          if (data is List) {
            return data;
          }
        }

        throw Exception(
          'Invalid address response from server.',
        );
      }

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final message =
              decoded['message']?.toString();

          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        }
      } catch (error) {
        if (error is Exception) {
          rethrow;
        }
      }

      throw Exception(
        'Failed to load customer addresses. '
        'Status code: ${response.statusCode}',
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load customer address.',
      );
    }
  }

  // ============================================================
  // CREATE CUSTOMER ADDRESS
  // ============================================================

  static Future<Map<String, dynamic>> createAddress({
    required int customerId,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    String? landmark,
    required String city,
    required String pincode,
  }) async {
    final url = Uri.parse(
      '$baseUrl/addresses',
    );

    final body = {
      'customer_id': customerId,
      'house_flat_number': houseFlatNumber,
      'apartment_name': apartmentName,
      'street_area': streetArea,
      'landmark': landmark ?? '',
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to create customer address.',
      );
    }
  }

  // ============================================================
  // UPDATE CUSTOMER ADDRESS
  // ============================================================

  static Future<Map<String, dynamic>> updateAddress({
    required int addressId,
    required String houseFlatNumber,
    required String apartmentName,
    required String streetArea,
    String? landmark,
    required String city,
    required String pincode,
  }) async {
    final url = Uri.parse(
      '$baseUrl/addresses/$addressId',
    );

    final body = {
      'house_flat_number': houseFlatNumber,
      'apartment_name': apartmentName,
      'street_area': streetArea,
      'landmark': landmark ?? '',
      'city': city,
      'pincode': pincode,
    };

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to update customer address.',
      );
    }
  }

  // ============================================================
  // CUSTOMER LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> loginCustomer({
    required String mobile,
  }) async {
    final url = Uri.parse(
      '$baseUrl/customers/login',
    );

    final body = {
      'mobile': mobile.trim(),
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to login. Please try again.',
      );
    }
  }

  // ============================================================
  // HANDLE HTTP RESPONSE
  // ============================================================

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    Map<String, dynamic> responseData;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        responseData = decoded;
      } else {
        throw Exception(
          'Invalid response format received from backend.',
        );
      }
    } catch (_) {
      throw Exception(
        'Invalid response received from the backend.',
      );
    }

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return responseData;
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    final message =
        responseData['message']?.toString().trim();

    if (message != null && message.isNotEmpty) {
      throw Exception(message);
    }

    throw Exception(
      'Request failed with status code '
      '${response.statusCode}.',
    );
  }

  // ============================================================
  // INTEGER PARSER
  // ============================================================

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }
}

