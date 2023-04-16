import 'package:flutter/material.dart';
import 'package:project1/constants/routes.dart';
import 'package:project1/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => VerifyEmailViewState();
}

class VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: Column(children: [
        const Text(
            'We have already send an email verification.Please open it to verify account'),
        const Text(
            'if you have not received a verification email then press the button below'),
        TextButton(
          onPressed: () async {
            await AuthService.firebase().sendEmailVerification();
          },
          child: const Text('Send email verification'),
        ),
        TextButton(
            onPressed: () async {
              await AuthService.firebase().logOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(registerroute, (route) => (false));
            },
            child: const Text('Restart'))
      ]),
    );
  }
}
