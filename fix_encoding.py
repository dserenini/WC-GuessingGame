import os

mojibake_map = {
    'VocÃª': 'Você',
    'estÃ¡': 'está',
    'Ã‰': 'É',
    'sÃ©rio': 'sério',
    'ðŸ˜±': '😱',
    'ðŸ †': '🏆',
    'ðŸ›¡ï¸ ': '🛡️ ',
    'ðŸ›¡ï¸': '🛡️',
    'ðŸ”§': '🔧',
    'ðŸšª': '🚪',
    'ðŸ ³': '🏳️',
    'ðŸ‡§ðŸ‡·': '🇧🇷',
    'ðŸ‡ºðŸ‡¸': '🇺🇸',
    'ðŸ‡®ðŸ‡¹': '🇮🇹',
    'ðŸŽ²': '🎲',
    'ðŸ”´': '🔴',
    'ðŸŽ¯': '🎯',
    'âœ…': '✅',
    'ðŸ¥‡': '🥇',
    'ðŸ¥ˆ': '🥈',
    'ðŸ¥‰': '🥉',
    'piÃ¹': 'più',
    'TÃ¼rkiye': 'Türkiye',
    'CuraÃ§ao': 'Curaçao',
    'Ã£': 'ã',
    'Ãµ': 'õ',
    'Ã¡': 'á',
    'Ã©': 'é',
    'Ã­': 'í',
    'Ã³': 'ó',
    'Ãº': 'ú',
    'Ã§': 'ç',
    'Ã¢': 'â',
    'Ãª': 'ê',
    'Ã´': 'ô',
    'Ã ': 'à',
    'â€"': '—',
    'â€“': '–',
}

def fix_mojibake(content):
    fixed = content
    for bad, good in mojibake_map.items():
        fixed = fixed.replace(bad, good)
    return fixed

def process_directory(directory):
    for root, _, files in os.walk(directory):
        if 'generated' in root or '.dart_tool' in root:
            continue
        for file in files:
            if file.endswith('.dart') or file.endswith('.arb'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    fixed_content = fix_mojibake(content)
                    
                    if fixed_content != content:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(fixed_content)
                        print(f"Fixed: {filepath}")
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")

if __name__ == '__main__':
    base_dir = r"c:\Users\Danilo\OneDrive\Documentos\2026\Python\BolaoCopa"
    process_directory(os.path.join(base_dir, 'lib'))
    process_directory(os.path.join(base_dir, 'scratch_l10n'))

