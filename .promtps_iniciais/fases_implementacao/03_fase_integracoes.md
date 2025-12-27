# Fase 3 - Integrações (Semanas 8-9)

## Semana 8: Google Maps + Clima

### Google Maps Platform
- [ ] Ativar APIs: Places, Directions, Maps JavaScript
- [ ] Criar chave de API com restrições
- [ ] Implementar service `maps-integration`:
  - `searchPlaces(query, location)` - busca POIs
  - `getDirections(origin, dest)` - rotas e tempo
  - `getPlaceDetails(placeId)` - detalhes do local
- [ ] Configurar cache Redis para resultados (TTL 24h)

### OpenWeather
- [ ] Criar conta e obter API key
- [ ] Implementar service `weather-integration`:
  - `getForecast(city, dates)` - previsão 7 dias
- [ ] Integrar como tool do Bedrock Agent

## Semana 9: Hospedagens

### Booking.com Affiliate
- [ ] Aplicar ao programa de afiliados
- [ ] Implementar `booking-integration`:
  - `searchHotels(city, dates, guests)` - busca
  - `getHotelDetails(hotelId)` - detalhes
  - `generateAffiliateLink(hotelId)` - deep link

### Airbnb (Scraping)
- [ ] Configurar serviço de scraping (ScraperAPI/Bright Data)
- [ ] Implementar `airbnb-integration`:
  - `searchListings(city, dates, guests)` - busca
  - `getListingDetails(listingId)` - detalhes
- [ ] Respeitar rate limits e robots.txt

### AviationStack (Voos)
- [ ] Criar conta e obter API key
- [ ] Implementar `flights-integration`:
  - `getFlightStatus(flightNumber)` - status em tempo real
  - `searchAirports(query)` - busca aeroportos

---

## Checklist de Conclusão Fase 3

- [ ] Google Maps retornando lugares e rotas
- [ ] Clima funcionando como tool do agente
- [ ] Busca de hotéis Booking integrada
- [ ] Busca de Airbnb integrada
- [ ] Cache Redis configurado
- [ ] Rate limiting implementado
