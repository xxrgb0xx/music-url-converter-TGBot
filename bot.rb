require 'telegram/bot'
require 'rspotify' ### https://github.com/guilhermesad/rspotify
require 'rspotify/oauth'
require 'yaml'
require_relative 'ya_music.rb'
require_relative 'spotify.rb'
#######################################################################################################################
config = YAML.load_file("config.yaml")
tg_token = config["telegram"]["tg_token"]
#######################################################################################################################
Telegram::Bot::Client.run(tg_token) do |bot|
    bot.listen do |message|
        case message.to_s
            ###########################################################################################################
            when '/start'
                bot.api.send_message(chat_id: message.chat.id, text: "Вечер в хату, #{message.from.first_name}!")
            ###########################################################################################################
            when '/stop'
                bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!")
            ###########################################################################################################
            when /[Хх][Уу][ИиЙй|ЕеЁё|Яя]/
                puts "Попало под хуевый кейс"
                bot.api.send_message(chat_id: message.chat.id, text: "Ты чё, пёс?!")
            ############################################################################################################
            when /.*https:\/\/open.spotify.com\/artist\/.*/ ### Получили ссылку на исполнителя в Spotify ###############
                puts "Получили ссылку на исполнителя в Spotify"
                artist_id = message.text[/(?<=https:\/\/open.spotify.com\/artist\/)\S*/]
                artist_name = spotify_get_name(artist_id, nil, nil)
                if artist_name == "@NoArtist!"
                    bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Spotify нет исполнителя ID##{artist_id}")
                else
                    ya_music_url = ya_music_get_id(artist_name,nil,nil)
                    if ya_music_url == "@NoArtist!"
                        bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Яндекс.Музыке нет исполнителя ARTIST##{artist_name}")
                    else
                        bot.api.send_message(chat_id: message.chat.id, text: "#{ya_music_url}")
                    end
                end 
            ############################################################################################################
            when /.*https:\/\/open.spotify.com\/album\/.*/ ### Получили ссылку на альбом в Spotify #####################
                puts "Получили ссылку на альбом в Spotify"
                album_id = message.text[/(?<=https:\/\/open.spotify.com\/album\/)\S*/]
                arg = spotify_get_name(nil, album_id, nil)
                artist_name = arg[0]
                album_name = arg [1]
                ya_music_url = ya_music_get_id(artist_name, album_name, nil)
                if ya_music_url == "@NoAlbum!"
                    bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Яндекс.Музыке нет альбома ALBUM##{album_name}")
                else
                    bot.api.send_message(chat_id: message.chat.id, text: "#{ya_music_url}")
                end
            ############################################################################################################
            when /.*https:\/\/open.spotify.com\/track\/.*/ ### Получили ссылку на трек в Spotify #######################
                puts "Получили ссылку на трек в Spotify"
                track_id = message.text[/(?<=https:\/\/open.spotify.com\/track\/)\S*/]
                arg = spotify_get_name(nil, nil, track_id)
                artist_name = arg[0]
                album_name = arg[1]
                track_name = arg[2]
                ya_music_url = ya_music_get_id(artist_name, album_name, track_name)
                if ya_music_url == "@NoTrack!"
                    bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Яндекс.Музыке нет трека TRACK##{track_name}")
                else
                    bot.api.send_message(chat_id: message.chat.id, text: "#{ya_music_url}")
                end
            ############################################################################################################
            when /.*https:\/\/music.yandex.ru\/album\/.*\/track\/.*/ ### Получили ссылку на трек в Яндекс.Музыке #######
                puts "Получили ссылку на трек в Яндекс.Музыке"
                album_id = message.text[/(?<=\/album\/)\d*/]
                track_id = message.text[/(?<=\/track\/)\S*/]
                arg = ya_music_get_name(nil, album_id, track_id)
                if arg != "@WrongUrl!"
                    artist_name = arg[0]
                    album_name = arg[1]
                    track_name = arg[2]
                    spotify_url = spotify_get_id(artist_name, album_name, track_name)                
                    if spotify_url == "@NoArtist!"
                        bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Spotify нет исполнителя ARTIST##{artist_name}")
                    elsif spotify_url == "@NoAlbum!"
                        bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Spotify нет альбома ALBUM##{album_name}")
                    elsif spotify_url == "@NoTrack!"
                        bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Spotify нет трека TRACK##{track_name}")
                    else
                        bot.api.send_message(chat_id: message.chat.id, text: "#{spotify_url}")
                    end    
                else
                    bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНекорректная ссылка на Яндекс.Музыку.")
                end    
            ############################################################################################################
            when /.*https:\/\/music.yandex.ru\/album\// ### Получили ссылку на альбом в Яндекс.Музыке ##################
                puts "Получили ссылку на альбом в Яндекс.Музыке"
                album_id = message.text[/(?<=https:\/\/music.yandex.ru\/album\/)\d*(?=\s*)/]
                arg = ya_music_get_name(nil, album_id, nil)
                if arg != "@WrongUrl!"
                    artist_name = arg[0]
                    album_name = arg[1]
                    spotify_url = spotify_get_id(artist_name, album_name, nil)
                        if spotify_url == "@NoArtist!"
                            bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Spotify нет исполнителя ARTIST##{artist_name}")
                        elsif spotify_url == "@NoAlbum!"
                            bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Spotify нет альбома ALBUM##{album_name}")
                        else 
                            bot.api.send_message(chat_id: message.chat.id, text: "#{spotify_url}")
                        end
                else
                    bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНекорректная ссылка на Яндекс.Музыку.")                    
                end
            ############################################################################################################
            when /.*https:\/\/music.yandex.ru\/artist\/.*/ ### Получили ссылку на иполнителя в Яндекс.Музыке ###########
                puts "Получили ссылку на иполнителя в Яндекс.Музыка"
                artist_id = message.text[/(?<=https:\/\/music.yandex.ru\/artist\/)\S*/]
                artist_name = ya_music_get_name(artist_id, nil, nil)
                if artist_name == "@WrongUrl!"
                    bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНекорректная ссылка на Яндекс.Музыку.")  
                else    
                    spotify_url = spotify_get_id(artist_name, nil, nil)
                    if spotify_url == "@NoArtist!"
                        bot.api.send_message(chat_id: message.chat.id, text: "У меня не получилось :(\nНа Spotify нет исполнителя ARTIST##{artist_name}")
                    else
                        bot.api.send_message(chat_id: message.chat.id, text: "#{spotify_url}")
                    end
                end    
        end
    end
end
