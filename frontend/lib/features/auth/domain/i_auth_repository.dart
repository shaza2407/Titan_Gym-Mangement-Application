import 'auth_model.dart';
import 'user_model.dart';

abstract class IAuthRepository {
  Future<UserModel> signUp(SignUpRequest request);
  Future<void> verifyEmail(VerifyEmailRequest request);
  Future<void> resendVerification(String email);
  Future<void> forgotPassword(ForgotPasswordRequest request);
  Future<void> resetPassword(ResetPasswordRequest request);
  Future<LoginResponse> signIn(LoginRequest request);
  Future<ClientProfileResponse> getClientProfile(String token);
}