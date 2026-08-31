import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InternetController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _internetCheckTimer;

  // Reactive flag — UI aana par automatically react thase, dialog ni jarur nathi
  final RxBool hasInternet = true.obs;
  final RxBool isChecking = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _initConnectivity() async {
    List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (_) {
      result = [ConnectivityResult.none];
    }
    await _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    final isNetworkAvailable = result.any(
      (item) => item != ConnectivityResult.none,
    );

    if (!isNetworkAvailable) {
      hasInternet.value = false;
      _internetCheckTimer?.cancel();
      return;
    }

    final realInternet = await _hasActualInternetAccess();
    hasInternet.value = realInternet;

    if (realInternet) {
      _internetCheckTimer?.cancel();
    } else {
      _startPeriodicInternetCheck();
    }
  }

  Future<bool> _hasActualInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _startPeriodicInternetCheck() {
    _internetCheckTimer?.cancel();
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final ok = await _hasActualInternetAccess();
      if (ok) {
        hasInternet.value = true;
        _internetCheckTimer?.cancel();
      }
    });
  }

  /// "Try Again" button mate
  Future<void> checkConnectionManually() async {
    isChecking.value = true;
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);
    isChecking.value = false;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _internetCheckTimer?.cancel();
    super.onClose();
  }
}

class NoInternetOverlay extends StatelessWidget {
  const NoInternetOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InternetController>();

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 50),
                const SizedBox(height: 16),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Obx(
                  () => controller.isChecking.value
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: controller.checkConnectionManually,
                          child: const Text('Try Again'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
