import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/router.dart';
import 'package:copa2026/core/theme.dart';
import 'package:copa2026/shared/providers/theme_provider.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';

class Copa2026App extends ConsumerWidget {
  // Proporção do aplicativo (Largura/Altura).
  // Escolhemos 10/16 (o equivalente portrait de 16:10) por ser uma excelente
  // proporção áurea que remete a dispositivos móveis/tablets sem ficar excessivamente larga.
  static const double kAppAspectRatio = 10 / 16;

  const Copa2026App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Make Bolão Great Again',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'),
        Locale('en'),
        Locale('it'),
      ],
      routerConfig: router,
      builder: (context, child) {
        // O fundo agora usa exatamente a mesma cor do Scaffold do tema atual,
        // eliminando qualquer "fronteira" visual entre o app e a área externa.
        final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

        // A largura máxima passa a ser definida mantendo a proporção estipulada (10:16)
        // em relação à altura total do navegador.
        final screenHeight = MediaQuery.of(context).size.height;
        final maxWidthByRatio = screenHeight * Copa2026App.kAppAspectRatio;

        return Container(
          color: backgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidthByRatio),
              child: ClipRect(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
