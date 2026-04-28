import 'package:flutter/material.dart';
import '../../data/models/auth_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/microsoft_auth_service.dart';

enum MicrosoftSignInNextStep { dashboard, register }

class MicrosoftSignInResult {
  final MicrosoftSignInNextStep nextStep;
  final MicrosoftIdentity? identity;

  const MicrosoftSignInResult({required this.nextStep, this.identity});
}

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final MicrosoftAuthService _microsoftAuthService = MicrosoftAuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isBootstrapping = false;
  bool get isBootstrapping => _isBootstrapping;

  UserModel? _user;
  UserModel? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setBootstrapping(bool value) {
    _isBootstrapping = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(email, password);
      _user = response.user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<MicrosoftIdentity?> authenticateMicrosoft() async {
    _setLoading(true);
    _setError(null);

    try {
      final identity = await _microsoftAuthService.authenticate();
      _setLoading(false);
      return identity;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<MicrosoftSignInResult?> signInWithMicrosoft() async {
    _setLoading(true);
    _setError(null);

    try {
      final identity = await _microsoftAuthService.authenticate();
      final backendResult = await _authService.authenticateMicrosoftAccessToken(
        identity.microsoftAccessToken,
      );

      if (backendResult.userExists) {
        _user = backendResult.authResponse?.user;
        _setLoading(false);
        return const MicrosoftSignInResult(
          nextStep: MicrosoftSignInNextStep.dashboard,
        );
      }

      _setLoading(false);
      return MicrosoftSignInResult(
        nextStep: MicrosoftSignInNextStep.register,
        identity: identity,
      );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<bool> register({
    required String email,
    required String gmailAccount,
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.register(
        email: email,
        gmailAccount: gmailAccount,
        username: username,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
      );
      _user = response.user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<MicrosoftIdentity?> registerWithMicrosoft() async {
    return authenticateMicrosoft();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    if (_isBootstrapping) {
      return;
    }

    _setBootstrapping(true);
    try {
      _user = await _authService.fetchCurrentUserProfile();
      _setError(null);
    } catch (_) {
      await _authService.logout();
      _user = null;
    } finally {
      _setBootstrapping(false);
      notifyListeners();
    }
  }

  Future<PasswordResetRequestResult?> requestPasswordReset(
    String identifier,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.requestPasswordReset(identifier);
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<PasswordResetOtpVerification?> verifyPasswordResetOtp({
    required String identifier,
    required String otp,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.verifyPasswordResetOtp(
        identifier: identifier,
        otp: otp,
      );
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String resetToken,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.resetPasswordWithOtp(
        resetToken: resetToken,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
