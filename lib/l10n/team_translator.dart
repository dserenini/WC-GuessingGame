import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

String translateTeam(BuildContext context, String dbTeamName) {
  final l = AppLocalizations.of(context)!;

  switch (dbTeamName) {
    case 'Mexico':
      return l.teamMexico;
    case 'South Africa':
      return l.teamSouthAfrica;
    case 'South Korea':
      return l.teamSouthKorea;
    case 'Czechia':
      return l.teamCzechia;
    case 'Canada':
      return l.teamCanada;
    case 'Switzerland':
      return l.teamSwitzerland;
    case 'Qatar':
      return l.teamQatar;
    case 'Bosnia and Herzegovina':
      return l.teamBosniaAndHerzegovina;
    case 'Brazil':
      return l.teamBrazil;
    case 'Morocco':
      return l.teamMorocco;
    case 'Haiti':
      return l.teamHaiti;
    case 'Scotland':
      return l.teamScotland;
    case 'United States':
      return l.teamUnitedStates;
    case 'Paraguay':
      return l.teamParaguay;
    case 'Australia':
      return l.teamAustralia;
    case 'Türkiye':
      return l.teamTurkiye;
    case 'Germany':
      return l.teamGermany;
    case 'Curaçao':
      return l.teamCuracao;
    case 'Ivory Coast':
      return l.teamIvoryCoast;
    case 'Ecuador':
      return l.teamEcuador;
    case 'Netherlands':
      return l.teamNetherlands;
    case 'Japan':
      return l.teamJapan;
    case 'Sweden':
      return l.teamSweden;
    case 'Tunisia':
      return l.teamTunisia;
    case 'Belgium':
      return l.teamBelgium;
    case 'Egypt':
      return l.teamEgypt;
    case 'IR Iran':
      return l.teamIRIran;
    case 'New Zealand':
      return l.teamNewZealand;
    case 'Spain':
      return l.teamSpain;
    case 'Cabo Verde':
      return l.teamCaboVerde;
    case 'Saudi Arabia':
      return l.teamSaudiArabia;
    case 'Uruguay':
      return l.teamUruguay;
    case 'France':
      return l.teamFrance;
    case 'Senegal':
      return l.teamSenegal;
    case 'Iraq':
      return l.teamIraq;
    case 'Norway':
      return l.teamNorway;
    case 'Argentina':
      return l.teamArgentina;
    case 'Algeria':
      return l.teamAlgeria;
    case 'Austria':
      return l.teamAustria;
    case 'Jordan':
      return l.teamJordan;
    case 'Portugal':
      return l.teamPortugal;
    case 'DR Congo':
      return l.teamDRCongo;
    case 'Uzbekistan':
      return l.teamUzbekistan;
    case 'Colombia':
      return l.teamColombia;
    case 'England':
      return l.teamEngland;
    case 'Croatia':
      return l.teamCroatia;
    case 'Ghana':
      return l.teamGhana;
    case 'Panama':
      return l.teamPanama;
    default:
      return dbTeamName; // Fallback to DB name if not found
  }
}
