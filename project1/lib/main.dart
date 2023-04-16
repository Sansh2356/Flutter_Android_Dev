import 'package:flutter/material.dart';
import 'package:project1/services/auth/auth_service.dart';
import 'package:project1/views/login_view.dart';
import 'package:project1/views/register_view.dart';
import 'constants/routes.dart';
import 'package:project1/views/verify_email_view.dart';
import 'package:project1/views/notes_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(primarySwatch: Colors.orange),
    home: const HomePage(),
    routes: {
      loginroute: (context) => const LoginView(),
      registerroute: (context) => const RegisterView(),
      notesroute: (context) => const NotesView(),
      verifyEmailroute: (context) => const VerifyEmailView(),
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initilize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              if (user.isEmailVerified) {
                return const NotesView();
              } else {
                return (const LoginView());
              }
            } else {
              return (const VerifyEmailView());
            }
          default:
            return (const CircularProgressIndicator());
        }
      },
    );
  }
}
