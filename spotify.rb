require 'rspotify' ### https://github.com/guilhermesad/rspotify
require 'rspotify/oauth'
require 'yaml'

config = YAML.load_file("config.yaml")
spotify_uid = config["spotify"]["spotify_uid"]
spotify_token = config["spotify"]["spotify_token"]

RSpotify::authenticate(spotify_uid, spotify_token)

def spotify_get_name(artist_id_arg, album_id_arg, song_id_arg)
    case 
        #####################################################################################################
        when artist_id_arg && album_id_arg == nil && song_id_arg == nil ### Запрашивается исполнитель #######
            begin ### Отлавливаем ошибки
                artist = RSpotify::Artist.find(artist_id_arg).name
                rescue RestClient::BadRequest => error
                rescue RestClient::NotFound => error
                puts error
            end
            if artist
                return artist
            else
                return '@NoArtist!'
            end 
        #####################################################################################################
        when artist_id_arg == nil && album_id_arg && song_id_arg == nil ### Запрашивается альбом ############
            begin ### Отлавливаем ошибки
                album_raw = RSpotify::Album.find(album_id_arg)
                rescue RestClient::BadRequest => error
                rescue RestClient::NotFound => error
                puts error
            end
            if album_raw
                album_name = album_raw.name
                artist_name = album_raw.artists[0].name
                return artist_name, album_name     
            else
                return '@NoAlbum!'
            end   
        #####################################################################################################
        when artist_id_arg == nil && album_id_arg == nil && song_id_arg ### Запрашивается трек ##############
            begin ### Отлавливаем ошибки
                track_raw = RSpotify::Track.find(song_id_arg)
                rescue RestClient::BadRequest => error
                rescue RestClient::NotFound => error
                puts error
            end
            if track_raw
                artist_name = track_raw.artists[0].name
                album_name = track_raw.album.name
                track_name = track_raw.name
                return artist_name, album_name, track_name
            else
                return '@NoTrack!'
            end
    end
end
####################################################################################################
def spotify_get_id(artist_arg, album_arg, song_arg)
    case
        ############################################################################################        
        when artist_arg && album_arg == nil && song_arg == nil ### Запрашивается исполнитель #######
            begin ### Отлавливаем ошибку.              
                artists_raw = RSpotify::Artist.search(artist_arg)
                artists_names = []
                artists_raw.each do |current_artist|
                    artists_names << current_artist.name.upcase
                end
                artist_number = artists_names.index(artist_arg.upcase)
                artist_raw = artists_raw[artist_number]
                rescue RestClient::BadRequest => error
                rescue RestClient::NotFound => error
            end
            if artist_raw
                artist_id = artist_raw.id
                url = "https://open.spotify.com/artist/#{artist_id}"
                return url
            else
                return '@NoArtist!'
            end
        ############################################################################################            
        when artist_arg && album_arg && song_arg == nil ### Запрашивается альбом ###################
            begin ### Ищем запрашиваемого исполнителя
                artists_raw = RSpotify::Artist.search(artist_arg)
                artists_names = []
                artists_raw.each do |current_artist|
                    artists_names << current_artist.name.upcase
                end
                artist_number = artists_names.index(artist_arg.upcase)
                artist_raw = artists_raw[artist_number]
                rescue RestClient::BadRequest => error
                rescue RestClient::NotFound => error
            end
            if  artist_raw
                artist_name = artist_raw.name
                artist_id = artist_raw.id
                begin ### Ищем альбомы исполнителя
                    albums_raw = []
                    albums_names = []
                    albums_ids = []                                  
                    offset = 0
                    counter = 0
                    while counter < 4 ### Запрашиваем первые 200 альбомов исполнителя (4 раза по 50).
                        albums_raw << artist_raw.albums(limit: 50, offset: offset)
                        counter += 1
                        offset += 50
                    end
                    albums_raw.each do |current_array| ### Получаем массивы с названиями и id альбомов
                        current_array.each do |current_album|
                            albums_names << current_album.name.upcase
                            albums_ids << current_album.id
                        end
                    end
                    rescue RestClient::BadRequest => error
                    rescue RestClient::NotFound => error
                end
                album_number = albums_names.index(album_arg.upcase) ### Получаем номер запрашиваемого альбома из массива
                if album_number ### Если в массиве альбомов есть запрашиваемый
                    album_id = albums_ids[album_number]
                    url = "https://open.spotify.com/album/#{album_id}"
                    return url        
                else
                    return '@NoAlbum!'
                end
            else
                return '@NoArtist!'
            end  
        ############################################################################################            
        when artist_arg && album_arg && song_arg ### Запрашивается трек ############################
            begin ### Ищем запрашиваемого исполнителя
                artists_raw = RSpotify::Artist.search(artist_arg)
                artists_names = []
                artists_raw.each do |current_artist|
                    artists_names << current_artist.name.upcase
                end
                artist_number = artists_names.index(artist_arg.upcase)
                artist_raw = artists_raw[artist_number]
                rescue RestClient::BadRequest => error
                rescue RestClient::NotFound => error
            end
            if artist_raw
                artist_name = artist_raw.name
                artist_id = artist_raw.id
                begin ### Ищем альбомы исполнителя
                    albums_raw = []
                    albums_names = []
                    albums_ids = []                                  
                    offset = 0
                    counter = 0
                    while counter < 4 ### Запрашиваем первые 200 альбомов исполнителя (4 раза по 50)
                        albums_raw << artist_raw.albums(limit: 50, offset: offset)
                        counter += 1
                        offset += 50
                    end
                    albums_raw.each do |current_array| ### Получаем массивы с названиями и id альбомов
                        current_array.each do |current_album|
                            albums_names << current_album.name.upcase
                            albums_ids << current_album.id
                        end
                    end
                    rescue RestClient::BadRequest => error
                    rescue RestClient::NotFound => error
                end
                album_number = albums_names.index(album_arg.upcase) ### Получаем номер запрашиваемого альбома из массива
                if album_number ### Если в массиве альбомов есть запрашиваемый
                    begin ### Получаем id альбома по номеру в массиве
                        album_id = albums_ids[album_number]
                        rescue RestClient::BadRequest => error
                        rescue RestClient::NotFound => error
                    end   
                    begin ### Получаем список треков с альбома
                        album_raw = RSpotify::Album.find(album_id)
                        tracks_raw = album_raw.tracks
                        rescue RestClient::BadRequest => error
                        rescue RestClient::NotFound => error
                    end
                    tracks_names = [] ### Создаем массивы с именами и id треков
                    tracks_ids = [] 
                    tracks_raw.each do |current_track| 
                        tracks_names << current_track.name.upcase
                        tracks_ids << current_track.id
                    end
                    track_number = tracks_names.index(song_arg.upcase) ### Получаем номер трека в массиве
                    if track_number
                        track_id = tracks_ids[track_number]           
                        url = "https://open.spotify.com/track/#{track_id}"
                        return url
                    else
                        return '@NoTrack!'
                    end
                else                     
                    return '@NoAlbum!'
                end
            else
                return '@NoArtist!'
            end
    end    
end