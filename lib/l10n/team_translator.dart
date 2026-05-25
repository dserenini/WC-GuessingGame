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
