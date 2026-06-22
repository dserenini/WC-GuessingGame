import 'package:flutter/material.dart';

/// Faixa vermelha fixa no topo sinalizando que o app está rodando no
/// AMBIENTE DE TESTES (staging). Renderizada como overlay (sobrepõe o
/// conteúdo) e não intercepta toques — ver uso em [Copa2026App.build].
class StagingBanner extends StatelessWidget {
  const StagingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        color: const Color(0xFFD32F2F), // vermelho
        // SafeArea pinta a área do notch/status bar de vermelho e mantém o
        // texto visível abaixo dela em PWAs instalados no celular.
        child: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: Text(
              'AMBIENTE DE TESTES',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
