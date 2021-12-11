require 'open-uri'
require 'nokogiri'
require 'addressable'

def ya_music_get_name (artist_id_arg, album_id_arg, song_id_arg)
    case
        #####################################################################################################################################
        when artist_id_arg && album_id_arg == nil && song_id_arg == nil ### Запрашивается исполнитель #######################################
            url = "https://music.yandex.ru/artist/#{artist_id_arg}" ### Парсим страницу поиска (ищем исполнителя) ################
            doc = get_html(url)
            if doc == nil
                return '@WrongUrl!'
            else    
                artist_div = doc.css("div.d-generic-page-head__main-top")
                if artist_div != nil
                    artist_name = artist_div.to_s[/(?<=class="page-artist__title typo-h1 typo-h1_big">).*(?=\<\/h1>)/]
                    if artist_name == nil
                        artist_name = artist_div.to_s[/(?<=class="page-artist__title typo-h1 typo-h1_small">).*(?=\<\/h1>)/]
                    end
                    return artist_name.gsub('&amp;','&')
                else
                    return '@NoArtist!'
                end
            end
        #####################################################################################################################################
        when artist_id_arg == nil && album_id_arg && song_id_arg == nil ### Запрашивается альбом ############################################
            url = "https://music.yandex.ru/album/#{album_id_arg}" ### Парсим страницу (ищем название альбома) ####################
            doc = get_html(url)
            if doc == nil
                return '@WrongUrl!'
            else
                artist_div = doc.css("div.d-album-summary__content")
                if artist_div.size != 0
                    album_div = doc.css("div.page-album__title")
                    if album_div.size !=0
                        artist_name = artist_div.to_s[/(?<=title=").*?(?=">)/]
                        album_name = album_div.to_s[/(?<=class="deco-typo">).*(?=<\/h1>)/]
                        album_version = album_div.to_s[/(?<=album__version">).*(?=<\/span>)/]
                        album_version2 = album_div.to_s[/(?<=album__version link">).*(?=<\/span>)/]
                        if album_version == nil && album_version2 == nil
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&')
                        elsif album_version != nil ### Если у альбома составное название
                            album_name = "#{album_name} (#{album_version})"
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&')
                        elsif album_version2 != nil ### Если у альбома составное название2
                            album_name = "#{album_name} (#{album_version2})"
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&')
                        end
                    else
                        return '@NoAlbum!'
                    end
                else
                    return '@NoArtist!'
                end
            end
        #############################################################################################################################################
        when artist_id_arg == nil && album_id_arg && song_id_arg || artist_id_arg == nil && album_id_arg == nil && song_id_arg ### Запрашивается трек
            if album_id_arg == nil ### Получена короткая ссылка на трек
                url = "https://music.yandex.ru/track/#{song_id_arg}"
                doc = get_html(url)
                if doc == nil
                    return '@WrongUrl!'
                else
                    artist_div = doc.css("div.page-album__title")
                    album_id_arg = artist_div.to_s[/(?<=<a href="\/album\/).*(?=" class)/] ### Получаем недостающий ID альбома
                end
            end        
            url = "https://music.yandex.ru/album/#{album_id_arg}/track/#{song_id_arg}" ### Парсим страницу (ищем название трека)
            doc = get_html(url)
            if doc == nil
                return '@WrongUrl!'
            else
                artist_div = doc.css("div.d-album-summary__content")
                album_div = doc.css("div.page-album__title")
                track_div = doc.css("div.sidebar__title")
                if artist_div.size != 0 && album_div.size != 0 && track_div.size != 0
                    artist_name = artist_div.to_s[/(?<=title=").*?(?=">)/]
                    album_name = album_div.to_s[/(?<=deco-link">).*(?=<\/a>)/]
                    if album_name == nil
                        album_name = album_div.to_s[/(?<=deco-typo">).*(?=<\/h1>)/]
                    end
                    album_version = album_div.to_s[/(?<=album__version link">).*(?=<\/span>)/]
                    album_version2 = album_div.to_s[/(?<=album__version">).*(?=<\/span>)/]
                    track_name = track_div.to_s[/(?<=class="d-link deco-link">).*(?=\<\/a>)/]
                    track_name_secondary = track_div.to_s[/(?<=class="deco-typo-secondary">\s).*(?=<\/span>)/]
                    if track_name_secondary == nil ### Если у трека простое название
                        if album_version == nil && album_version2 == nil ### Если у альбома простое название
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&'), track_name.gsub('&amp;','&')
                        elsif album_version != nil ### Если у альбома составное название
                            album_name = "#{album_name} (#{album_version})"
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&'), track_name.gsub('&amp;','&')
                        elsif album_version2 != nil ### Если у альбома составное название2
                            album_name = "#{album_name} (#{album_version2})"
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&'), track_name.gsub('&amp;','&')
                        end
                    else ### Если у трека составное название
                        track_name = "#{track_name} - #{track_name_secondary}"   
                        if album_version == nil && album_version2 == nil ### Если у альбома простое название
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&'), track_name.gsub('&amp;','&')
                        elsif album_version != nil ### Если у альбома составное название
                            album_name = "#{album_name} (#{album_version})"
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&'), track_name.gsub('&amp;','&')
                        elsif album_version2 != nil
                            album_name = "#{album_name} (#{album_version2})"
                            return artist_name.gsub('&amp;','&'), album_name.gsub('&amp;','&'), track_name.gsub('&amp;','&')
                        end
                    end        
                else
                    return '@NoTrack!'
                end
            end        
    end
end
#############################################################################################################################################
#############################################################################################################################################
def ya_music_get_id (artist_arg, album_arg, song_arg)
    case
        ###############################################################################################
        when artist_arg && album_arg == nil && song_arg == nil ### Запрашивается исполнитель ##########
        ### Парсим страницу поиска (ищем исполнителя) #################################################
            url = Addressable::URI.encode("https://music.yandex.ru/search?text=#{artist_arg}")
            doc = get_html(url)
            artists_div = doc.css("div.artist__name")
            if !artists_div.empty?
                artist_id = artists_div[0].to_s[/(?<=href="\/artist\/).*(?=" class=")/]
                url = "https://music.yandex.ru/artist/#{artist_id}"
                return url
            else
                return '@NoArtist!'
            end
        ###############################################################################################
        when artist_arg && album_arg && song_arg == nil ### Запрашивается альбом ######################
        ### Парсим страницу поиска (ищем исполнителя) #################################################
            url = Addressable::URI.encode("https://music.yandex.ru/search?text=#{artist_arg}")
            doc = get_html(url)
            artists_div = doc.css("div.artist__name")
            if !artists_div.empty?
                artist = artists_div[0].attr('title')
                artist_id = artists_div[0].to_s[/(?<=href="\/artist\/).*(?=" class=")/]
                ### Парсим страницу исполнителя (ищем альбом)
                url = "https://music.yandex.ru/artist/#{artist_id}/albums"
                doc = get_html(url)
                albums_div = doc.css("div.album__title")
                albums = []
                albums_div.each do |current_album|
                    albums << current_album.attr('title').upcase
                end
                album_number = albums.index(album_arg.upcase) ### Получаем порядковый номер искомого альбома
                if album_number
                    ### Парсим страницу альбома (ищем трек)
                    album_id = albums_div[album_number].to_s[/(?<=href="\/album\/).*(?=" class="d-link deco-link album__caption">)/]
                    url = "https://music.yandex.ru/album/#{album_id}"
                    return url
                else
                    return '@NoAlbum!'
                end  
            else
                return '@NoArtist!'
            end    
        ###############################################################################################
        when  artist_arg && album_arg && song_arg ### Запрашивается трек ##############################
        ### Парсим страницу поиска (ищем исполнителя) #################################################
            url = Addressable::URI.encode("https://music.yandex.ru/search?text=#{artist_arg}")
            doc = get_html(url)
            artists_div = doc.css("div.artist__name")
            if !artists_div.empty?
                artist = artists_div[0].attr('title')
                artist_id = artists_div[0].to_s[/(?<=href="\/artist\/).*(?=" class=")/]
                ### Парсим страницу исполнителя (ищем альбом)
                url = "https://music.yandex.ru/artist/#{artist_id}/albums"
                doc = get_html(url)
                albums_div = doc.css("div.album__title")
                albums = []
                albums_div.each do |current_album|
                    albums << current_album.attr('title').upcase
                end
                album_number = albums.index(album_arg.upcase) ### Получаем порядковый номер искомого альбома
                if album_number
                    album_id = albums_div[album_number].to_s[/(?<=href="\/album\/).*(?=" class="d-link deco-link album__caption">)/]
                    ### Парсим страницу альбома (ищем трек)
                    url = "https://music.yandex.ru/album/#{album_id}"
                    doc = get_html(url)
                    tracks_div = doc.css("div.d-track__name")
                    tracks = []
                    tracks_div.each do |current_track|
                            ### tracks << current_track.to_s[/(?<=deco-link_stronger">).*(?=<\/a>)/].upcase ### Яндекс обрамили пробелами название трека
                            tracks << current_track.to_s[/(?<=deco-link_stronger"> ).*(?= <\/a>)/].upcase
                    end
                    track_number = tracks.index(song_arg.upcase)
                    if track_number
                        track_id = tracks_div[track_number].to_s[/(?<=href="\/album\/#{album_id}\/track\/).*(?=" class="d-track__title)/]
                        url = "https://music.yandex.ru/album/#{album_id}/track/#{track_id}"
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