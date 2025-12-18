import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/core/widgets/app_button.dart';
import 'package:hope_link/core/widgets/app_text_field.dart';
import 'package:hope_link/features/Auth/controllers/user_registration_controller.dart';
import 'package:hope_link/features/Auth/widgets/registration_header.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final RxBool _obscurePassword = true.obs;

  late final UserRegistrationController _registrationController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _registrationController = Get.put(
      UserRegistrationController(),
      permanent: true,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Controllers are now managed by the UserRegistrationController
    super.dispose();
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      _registrationController.registerUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorToken.primary.color.withOpacity(0.05),
              Colors.white,
              AppColorToken.primary.color.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // _buildHeader(),///////////////registration header
                        RegistrationHeader(),
                        32.verticalSpace,
                        // _buildSignUpForm(),///////////////signup form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColorToken.primary.color.withOpacity(
                                  0.08,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // _buildNameField(),//////////////name field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Full Name',
                                      style: AppTextStyle.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AppTextField(
                                      controller: _registrationController
                                          .nameController,
                                      borderRadius: 12,
                                      hintText: 'John Doe',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                16.verticalSpace,
                                // ////////////email field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: AppTextStyle.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AppTextField(
                                      controller: _registrationController
                                          .emailController,
                                      borderRadius: 12,
                                      hintText: 'your.email@example.com',
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!GetUtils.isEmail(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                                16.verticalSpace,
                                // /////////////////////password field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password',
                                      style: AppTextStyle.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Obx(
                                      () => AppTextField(
                                        controller: _registrationController
                                            .passwordController,
                                        borderRadius: 12,
                                        hintText: '••••••••',
                                        obscureText: _obscurePassword.value,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword.value
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: Colors.grey[600],
                                          ),
                                          onPressed: () {
                                            _obscurePassword.toggle();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                24.verticalSpace,
                                // //////////signup button
                                Obx(
                                  () => AppButton(
                                    title:
                                        _registrationController.isLoading.value
                                        ? 'Creating Account...'
                                        : 'Sign Up',
                                    backgroundColor:
                                        AppColorToken.primary.color,
                                    onPressed:
                                        _registrationController.isLoading.value
                                        ? null
                                        : _handleSignUp,
                                    width: double.infinity,
                                    radius: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        24.verticalSpace,
                        // _buildLoginPrompt(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: AppTextStyle.bodySmall.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () => Get.offAllNamed('/login'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Sign In',
                                  style: AppTextStyle.bodySmall.copyWith(
                                    color: AppColorToken.primary.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildHeader() {
  //   return Column(
  //     children: [
  //       Container(
  //         width: 100,
  //         height: 100,
  //         decoration: BoxDecoration(
  //           color: AppColorToken.primary.color.withOpacity(0.1),
  //           shape: BoxShape.circle,
  //         ),
  //         child: Icon(
  //           Icons.volunteer_activism_rounded,
  //           size: 50,
  //           color: AppColorToken.primary.color,
  //         ),
  //       ),
  //       24.verticalSpace,
  //       Text(
  //         'Create Account',
  //         style: AppTextStyle.h3.bold.copyWith(
  //           fontSize: 32,
  //           color: AppColorToken.primary.color,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //       8.verticalSpace,
  //       Text(
  //         'Join our community of volunteers',
  //         style: AppTextStyle.bodySmall.copyWith(
  //           color: Colors.grey[600],
  //           fontSize: 16,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildSignUpForm() {
  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColorToken.primary.color.withOpacity(0.08),
  //           blurRadius: 30,
  //           offset: const Offset(0, 10),
  //         ),
  //       ],
  //     ),
  //     child: Form(
  //       key: _formKey,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           _buildNameField(),
  //           16.verticalSpace,
  //           _buildEmailField(),
  //           16.verticalSpace,
  //           _buildPasswordField(),
  //           24.verticalSpace,
  //           _buildSignUpButton(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _registrationController.nameController,
          borderRadius: 12,
          hintText: 'John Doe',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _registrationController.emailController,
          borderRadius: 12,
          hintText: 'your.email@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!GetUtils.isEmail(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _registrationController.passwordController,
          borderRadius: 12,
          hintText: '••••••••',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Obx(
      () => AppButton(
        title: _registrationController.isLoading.value
            ? 'Creating Account...'
            : 'Sign Up',
        backgroundColor: AppColorToken.primary.color,
        onPressed: _registrationController.isLoading.value
            ? null
            : _handleSignUp,
        width: double.infinity,
        radius: 12,
      ),
    );
  }

  // Widget _buildLoginPrompt() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           "Already have an account?",
  //           style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
  //         ),
  //         const SizedBox(width: 4),
  //         TextButton(
  //           onPressed: () => Get.offAllNamed('/login'),
  //           style: TextButton.styleFrom(
  //             padding: const EdgeInsets.symmetric(horizontal: 8),
  //             minimumSize: const Size(0, 0),
  //             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //           ),
  //           child: Text(
  //             'Sign In',
  //             style: AppTextStyle.bodySmall.copyWith(
  //               color: AppColorToken.primary.color,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
}
