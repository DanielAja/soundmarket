import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CountryDetectionService {
  static const String _defaultCountry = 'US';
  static const Duration _cacheExpiry = Duration(days: 1);

  static String? _cachedCountry;
  static DateTime? _cacheTime;

  static Future<String> getUserCountry() async {
    if (_isCacheValid()) {
      return _cachedCountry!;
    }

    try {
      String country = await _detectCountryFromLocale();

      if (country == _defaultCountry) {
        country = await _detectCountryFromIp();
      }

      _cacheCountry(country);
      return country;
    } catch (e) {
      print('Error detecting country: $e');
      return _defaultCountry;
    }
  }

  static Future<String> _detectCountryFromLocale() async {
    try {
      final String locale = Platform.localeName;
      final List<String> parts = locale.split('_');

      if (parts.length > 1) {
        final String countryCode = parts[1].toUpperCase();
        if (_isValidSpotifyMarket(countryCode)) {
          return countryCode;
        }
      }
    } catch (e) {
      print('Error getting locale: $e');
    }

    return _defaultCountry;
  }

  static Future<String> _detectCountryFromIp() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://ipapi.co/json/'),
            headers: {'User-Agent': 'SoundMarket-App/1.0'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String countryCode =
            data['country_code']?.toString().toUpperCase() ?? _defaultCountry;

        if (_isValidSpotifyMarket(countryCode)) {
          return countryCode;
        }
      }
    } catch (e) {
      print('Error getting country from IP: $e');
    }

    return _defaultCountry;
  }

  static bool _isValidSpotifyMarket(String countryCode) {
    const validMarkets = {
      'AD',
      'AE',
      'AG',
      'AL',
      'AM',
      'AO',
      'AR',
      'AT',
      'AU',
      'AZ',
      'BA',
      'BB',
      'BD',
      'BE',
      'BF',
      'BG',
      'BH',
      'BI',
      'BJ',
      'BN',
      'BO',
      'BR',
      'BS',
      'BT',
      'BW',
      'BY',
      'BZ',
      'CA',
      'CD',
      'CG',
      'CH',
      'CI',
      'CL',
      'CM',
      'CO',
      'CR',
      'CV',
      'CW',
      'CY',
      'CZ',
      'DE',
      'DJ',
      'DK',
      'DM',
      'DO',
      'DZ',
      'EC',
      'EE',
      'EG',
      'ES',
      'ET',
      'FI',
      'FJ',
      'FM',
      'FR',
      'GA',
      'GB',
      'GD',
      'GE',
      'GH',
      'GM',
      'GN',
      'GQ',
      'GR',
      'GT',
      'GW',
      'GY',
      'HK',
      'HN',
      'HR',
      'HT',
      'HU',
      'ID',
      'IE',
      'IL',
      'IN',
      'IQ',
      'IS',
      'IT',
      'JM',
      'JO',
      'JP',
      'KE',
      'KG',
      'KH',
      'KI',
      'KM',
      'KN',
      'KR',
      'KW',
      'KZ',
      'LA',
      'LB',
      'LC',
      'LI',
      'LK',
      'LR',
      'LS',
      'LT',
      'LU',
      'LV',
      'LY',
      'MA',
      'MC',
      'MD',
      'ME',
      'MG',
      'MH',
      'MK',
      'ML',
      'MN',
      'MO',
      'MR',
      'MT',
      'MU',
      'MV',
      'MW',
      'MX',
      'MY',
      'MZ',
      'NA',
      'NE',
      'NG',
      'NI',
      'NL',
      'NO',
      'NP',
      'NR',
      'NZ',
      'OM',
      'PA',
      'PE',
      'PG',
      'PH',
      'PK',
      'PL',
      'PS',
      'PT',
      'PW',
      'PY',
      'QA',
      'RO',
      'RS',
      'RW',
      'SA',
      'SB',
      'SC',
      'SE',
      'SG',
      'SI',
      'SK',
      'SL',
      'SM',
      'SN',
      'SR',
      'ST',
      'SV',
      'SZ',
      'TD',
      'TG',
      'TH',
      'TJ',
      'TL',
      'TN',
      'TO',
      'TR',
      'TT',
      'TV',
      'TW',
      'TZ',
      'UA',
      'UG',
      'US',
      'UY',
      'UZ',
      'VC',
      'VE',
      'VN',
      'VU',
      'WS',
      'XK',
      'ZA',
      'ZM',
      'ZW',
    };

    return validMarkets.contains(countryCode);
  }

  static void _cacheCountry(String country) {
    _cachedCountry = country;
    _cacheTime = DateTime.now();
  }

  static bool _isCacheValid() {
    if (_cachedCountry == null || _cacheTime == null) {
      return false;
    }

    return DateTime.now().difference(_cacheTime!).compareTo(_cacheExpiry) < 0;
  }

  static void clearCache() {
    _cachedCountry = null;
    _cacheTime = null;
  }

  static String? getCachedCountry() {
    return _isCacheValid() ? _cachedCountry : null;
  }

  static Map<String, String> getCountryDisplayInfo(String countryCode) {
    const countryNames = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'IT': 'Italy',
      'ES': 'Spain',
      'JP': 'Japan',
      'KR': 'South Korea',
      'BR': 'Brazil',
      'MX': 'Mexico',
      'IN': 'India',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'NL': 'Netherlands',
      'BE': 'Belgium',
      'CH': 'Switzerland',
      'AT': 'Austria',
      'PL': 'Poland',
      'CZ': 'Czech Republic',
      'HU': 'Hungary',
      'PT': 'Portugal',
      'IE': 'Ireland',
      'NZ': 'New Zealand',
      'SG': 'Singapore',
      'HK': 'Hong Kong',
      'MY': 'Malaysia',
      'TH': 'Thailand',
      'PH': 'Philippines',
      'ID': 'Indonesia',
      'VN': 'Vietnam',
      'TW': 'Taiwan',
      'IL': 'Israel',
      'AE': 'United Arab Emirates',
      'SA': 'Saudi Arabia',
      'EG': 'Egypt',
      'ZA': 'South Africa',
      'NG': 'Nigeria',
      'KE': 'Kenya',
      'GH': 'Ghana',
      'AR': 'Argentina',
      'CL': 'Chile',
      'CO': 'Colombia',
      'PE': 'Peru',
      'EC': 'Ecuador',
      'UY': 'Uruguay',
      'BO': 'Bolivia',
      'PY': 'Paraguay',
      'CR': 'Costa Rica',
      'PA': 'Panama',
      'GT': 'Guatemala',
      'HN': 'Honduras',
      'NI': 'Nicaragua',
      'SV': 'El Salvador',
      'DO': 'Dominican Republic',
      'JM': 'Jamaica',
      'TT': 'Trinidad and Tobago',
      'BB': 'Barbados',
      'RU': 'Russia',
      'TR': 'Turkey',
      'GR': 'Greece',
      'BG': 'Bulgaria',
      'RO': 'Romania',
      'HR': 'Croatia',
      'SI': 'Slovenia',
      'SK': 'Slovakia',
      'LT': 'Lithuania',
      'LV': 'Latvia',
      'EE': 'Estonia',
    };

    return {
      'code': countryCode,
      'name': countryNames[countryCode] ?? countryCode,
      'flag': _getCountryFlag(countryCode),
    };
  }

  static String _getCountryFlag(String countryCode) {
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
