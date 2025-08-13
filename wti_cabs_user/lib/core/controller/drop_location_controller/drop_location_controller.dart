import 'package:get/get.dart';
import '../../model/booking_engine/suggestions_places_response.dart';

class DestinationLocationController extends GetxController {
  var placeId = ''.obs;
  var title = ''.obs;
  var city = ''.obs;
  var state = ''.obs;
  var country = ''.obs;
  // var lat = 0.0.obs;
  // var lng = 0.0.obs;

  var types = <String>[].obs;
  var terms = <Term>[].obs;

  void setPlace({
    required String placeId,
    required String title,
    required String city,
    required String state,
    required String country,
    // required double lat,
    // required double lng,
    List<String>? types,
    List<Term>? terms,
  }) {
    print('--- setPlace destination called ---');
    print('placeId: $placeId');
    print('title: $title');
    print('city: $city');
    print('state: $state');
    print('country: $country');
    print('types: ${types ?? []}');
    print('terms: ${terms ?? []}');

    this.placeId.value = placeId;
    this.title.value = title;
    this.city.value = city;
    this.state.value = state;
    this.country.value = country;
    // this.lat.value = lat;
    // this.lng.value = lng;
    this.types.value = types ?? [];
    this.terms.value = terms ?? [];
  }

  String get termsJson => terms.map((e) => e.toJson()).toList().toString();
}
