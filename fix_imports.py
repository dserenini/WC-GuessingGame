import os, glob

for f in glob.glob('lib/**/*.dart', recursive=True):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    if "import 'package:copa2026/l10n/app_localizations.dart';" in content:
        content = content.replace("import 'package:copa2026/l10n/app_localizations.dart';", "import 'package:flutter_gen/gen_l10n/app_localizations.dart';")
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
