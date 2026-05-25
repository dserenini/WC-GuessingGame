import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

String translateTeam(BuildContext context, String dbTeamName) {
  final l = AppLocalizations.of(context)!;

  final name = dbTeamName.trim().toLowerCase();
  
  switch (name) {
    case 'mexico':
    case 'méxico':
    case 'messico':
      return l.teamMexico;
    case 'south africa':
    case 'áfrica do sul':
    case 'sudafrica':
      return l.teamSouthAfrica;
    case 'south korea':
    case 'coreia do sul':
    case 'corea del sud':
      return l.teamSouthKorea;
    case 'czechia':
    case 'chéquia':
    case 'cechia':
    case 'czech republic':
      return l.teamCzechia;
    case 'canada':
    case 'canadá':
      return l.teamCanada;
    case 'switzerland':
    case 'suíça':
    case 'svizzera':
      return l.teamSwitzerland;
    case 'qatar':
    case 'catar':
      return l.teamQatar;
    case 'bosnia and herzegovina':
    case 'bósnia e herzegovina':
    case 'bosnia ed erzegovina':
      return l.teamBosniaAndHerzegovina;
    case 'brazil':
    case 'brasil':
    case 'brasile':
      return l.teamBrazil;
    case 'morocco':
    case 'marrocos':
    case 'marocco':
      return l.teamMorocco;
    case 'haiti':
      return l.teamHaiti;
    case 'scotland':
    case 'escócia':
    case 'scozia':
      return l.teamScotland;
    case 'united states':
    case 'estados unidos':
    case 'stati uniti':
    case 'usa':
      return l.teamUnitedStates;
    case 'paraguay':
    case 'paraguai':
      return l.teamParaguay;
    case 'australia':
    case 'austrália':
      return l.teamAustralia;
    case 'türkiye':
    case 'turkey':
    case 'turquia':
    case 'turchia':
      return l.teamTurkiye;
    case 'germany':
    case 'alemanha':
    case 'germania':
      return l.teamGermany;
    case 'curaçao':
    case 'curacao':
      return l.teamCuracao;
    case 'ivory coast':
    case 'costa do marfim':
    case 'costa d\'avorio':
    case 'cote d\'ivoire':
      return l.teamIvoryCoast;
    case 'ecuador':
    case 'equador':
      return l.teamEcuador;
    case 'netherlands':
    case 'holanda':
    case 'paesi bassi':
      return l.teamNetherlands;
    case 'japan':
    case 'japão':
    case 'giappone':
      return l.teamJapan;
    case 'sweden':
    case 'suécia':
    case 'svezia':
      return l.teamSweden;
    case 'tunisia':
    case 'tunísia':
      return l.teamTunisia;
    case 'belgium':
    case 'bélgica':
    case 'belgio':
      return l.teamBelgium;
    case 'egypt':
    case 'egito':
    case 'egitto':
      return l.teamEgypt;
    case 'ir iran':
    case 'iran':
    case 'irã':
      return l.teamIRIran;
    case 'new zealand':
    case 'nova zelândia':
    case 'nuova zelanda':
      return l.teamNewZealand;
    case 'spain':
    case 'espanha':
    case 'spagna':
      return l.teamSpain;
    case 'cabo verde':
    case 'cape verde':
    case 'capo verde':
      return l.teamCaboVerde;
    case 'saudi arabia':
    case 'arábia saudita':
    case 'arabia saudita':
      return l.teamSaudiArabia;
    case 'uruguay':
    case 'uruguai':
      return l.teamUruguay;
    case 'france':
    case 'frança':
    case 'francia':
      return l.teamFrance;
    case 'senegal':
      return l.teamSenegal;
    case 'iraq':
    case 'iraque':
      return l.teamIraq;
    case 'norway':
    case 'noruega':
    case 'norvegia':
      return l.teamNorway;
    case 'argentina':
      return l.teamArgentina;
    case 'algeria':
    case 'argélia':
      return l.teamAlgeria;
    case 'austria':
    case 'áustria':
      return l.teamAustria;
    case 'jordan':
    case 'jordânia':
    case 'giordania':
      return l.teamJordan;
    case 'portugal':
    case 'portogallo':
      return l.teamPortugal;
    case 'dr congo':
    case 'rd congo':
    case 'rd del congo':
      return l.teamDRCongo;
    case 'uzbekistan':
    case 'uzbequistão':
      return l.teamUzbekistan;
    case 'colombia':
    case 'colômbia':
      return l.teamColombia;
    case 'england':
    case 'inglaterra':
    case 'inghilterra':
      return l.teamEngland;
    case 'croatia':
    case 'croácia':
    case 'croazia':
      return l.teamCroatia;
    case 'ghana':
      return l.teamGhana;
    case 'panama':
    case 'panamá':
      return l.teamPanama;
    default:
      return dbTeamName; // Fallback to DB name if not found
  }
}

String getTeamAbbreviation(BuildContext context, String dbTeamName) {
  final lang = Localizations.localeOf(context).languageCode;
  final name = dbTeamName.trim().toLowerCase();

  String abbr(String pt, String en, String it) {
    if (lang == 'pt') return pt;
    if (lang == 'it') return it;
    return en;
  }

  switch (name) {
    case 'mexico':
    case 'méxico':
    case 'messico':
      return abbr('MEX', 'MEX', 'MEX');
    case 'south africa':
    case 'áfrica do sul':
    case 'sudafrica':
      return abbr('AFS', 'RSA', 'RSA');
    case 'south korea':
    case 'coreia do sul':
    case 'corea del sud':
      return abbr('COR', 'KOR', 'KOR');
    case 'czechia':
    case 'chéquia':
    case 'cechia':
    case 'czech republic':
      return abbr('CZE', 'CZE', 'CZE');
    case 'canada':
    case 'canadá':
      return abbr('CAN', 'CAN', 'CAN');
    case 'switzerland':
    case 'suíça':
    case 'svizzera':
      return abbr('SUI', 'SUI', 'SUI');
    case 'qatar':
    case 'catar':
      return abbr('CAT', 'QAT', 'QAT');
    case 'bosnia and herzegovina':
    case 'bósnia e herzegovina':
    case 'bosnia ed erzegovina':
      return abbr('BIH', 'BIH', 'BIH');
    case 'brazil':
    case 'brasil':
    case 'brasile':
      return abbr('BRA', 'BRA', 'BRA');
    case 'morocco':
    case 'marrocos':
    case 'marocco':
      return abbr('MAR', 'MAR', 'MAR');
    case 'haiti':
      return abbr('HAI', 'HAI', 'HAI');
    case 'scotland':
    case 'escócia':
    case 'scozia':
      return abbr('ESC', 'SCO', 'SCO');
    case 'united states':
    case 'estados unidos':
    case 'stati uniti':
    case 'usa':
      return abbr('EUA', 'USA', 'USA');
    case 'paraguay':
    case 'paraguai':
      return abbr('PAR', 'PAR', 'PAR');
    case 'australia':
    case 'austrália':
      return abbr('AUS', 'AUS', 'AUS');
    case 'türkiye':
    case 'turkey':
    case 'turquia':
    case 'turchia':
      return abbr('TUR', 'TUR', 'TUR');
    case 'germany':
    case 'alemanha':
    case 'germania':
      return abbr('ALE', 'GER', 'GER');
    case 'curaçao':
    case 'curacao':
      return abbr('CUW', 'CUW', 'CUW');
    case 'ivory coast':
    case 'costa do marfim':
    case 'costa d\'avorio':
    case 'cote d\'ivoire':
      return abbr('CIV', 'CIV', 'CIV');
    case 'ecuador':
    case 'equador':
      return abbr('EQU', 'ECU', 'ECU');
    case 'netherlands':
    case 'holanda':
    case 'paesi bassi':
      return abbr('HOL', 'NED', 'NED');
    case 'japan':
    case 'japão':
    case 'giappone':
      return abbr('JAP', 'JPN', 'JPN');
    case 'sweden':
    case 'suécia':
    case 'svezia':
      return abbr('SUE', 'SWE', 'SWE');
    case 'tunisia':
    case 'tunísia':
      return abbr('TUN', 'TUN', 'TUN');
    case 'belgium':
    case 'bélgica':
    case 'belgio':
      return abbr('BEL', 'BEL', 'BEL');
    case 'egypt':
    case 'egito':
    case 'egitto':
      return abbr('EGI', 'EGY', 'EGY');
    case 'ir iran':
    case 'iran':
    case 'irã':
      return abbr('IRA', 'IRN', 'IRN');
    case 'new zealand':
    case 'nova zelândia':
    case 'nuova zelanda':
      return abbr('NZL', 'NZL', 'NZL');
    case 'spain':
    case 'espanha':
    case 'spagna':
      return abbr('ESP', 'ESP', 'ESP');
    case 'cabo verde':
    case 'cape verde':
    case 'capo verde':
      return abbr('CPV', 'CPV', 'CPV');
    case 'saudi arabia':
    case 'arábia saudita':
    case 'arabia saudita':
      return abbr('ARA', 'KSA', 'KSA');
    case 'uruguay':
    case 'uruguai':
      return abbr('URU', 'URU', 'URU');
    case 'france':
    case 'frança':
    case 'francia':
      return abbr('FRA', 'FRA', 'FRA');
    case 'senegal':
      return abbr('SEN', 'SEN', 'SEN');
    case 'iraq':
    case 'iraque':
      return abbr('IRQ', 'IRQ', 'IRQ');
    case 'norway':
    case 'noruega':
    case 'norvegia':
      return abbr('NOR', 'NOR', 'NOR');
    case 'argentina':
      return abbr('ARG', 'ARG', 'ARG');
    case 'algeria':
    case 'argélia':
      return abbr('ARG', 'ALG', 'ALG');
    case 'austria':
    case 'áustria':
      return abbr('AUT', 'AUT', 'AUT');
    case 'jordan':
    case 'jordânia':
    case 'giordania':
      return abbr('JOR', 'JOR', 'JOR');
    case 'portugal':
    case 'portogallo':
      return abbr('POR', 'POR', 'POR');
    case 'dr congo':
    case 'rd congo':
    case 'rd del congo':
      return abbr('COD', 'COD', 'COD');
    case 'uzbekistan':
    case 'uzbequistão':
      return abbr('UZB', 'UZB', 'UZB');
    case 'colombia':
    case 'colômbia':
      return abbr('COL', 'COL', 'COL');
    case 'england':
    case 'inglaterra':
    case 'inghilterra':
      return abbr('ING', 'ENG', 'ENG');
    case 'croatia':
    case 'croácia':
    case 'croazia':
      return abbr('CRO', 'CRO', 'CRO');
    case 'ghana':
      return abbr('GAN', 'GHA', 'GHA');
    case 'panama':
    case 'panamá':
      return abbr('PAN', 'PAN', 'PAN');
    default:
      if (dbTeamName.length >= 3) return dbTeamName.substring(0, 3).toUpperCase();
      return dbTeamName.toUpperCase().padRight(3, 'A');
  }
}
