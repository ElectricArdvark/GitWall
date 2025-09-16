import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/common_widget.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          color:
              appState.isDarkTheme
                  ? const Color(0xFF1F2A29)
                  : const Color(0xFFF5F5F5),
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: WindowTitleBarWithBorder(),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Logo
                    Image.asset('lib/assets/logo.ico', width: 80, height: 80),
                    const SizedBox(height: 30),

                    // App Name
                    Text(
                      'GitWall',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color:
                            appState.isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Welcome Text
                    Text(
                      'Welcome to GitWall',
                      style: TextStyle(
                        fontSize: 20,
                        color:
                            appState.isDarkTheme ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Description
                    SizedBox(
                      width: 400,
                      child: Text(
                        'Your modern desktop wallpaper changer.\nEasily set and manage wallpapers from various GitHub repositories.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              appState.isDarkTheme
                                  ? Colors.white70
                                  : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
