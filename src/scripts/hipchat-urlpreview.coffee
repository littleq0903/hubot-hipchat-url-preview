# Description:
#   preview the link content

request = require 'request'
cheerio = require 'cheerio'
readability = require 'node-readability'
hipchat = require 'node-hipchat'

capitalize = (s) ->
    splited = s.split("_")
    uppered = splited.map (w) -> 
        w[0] = w[0].toUpperCase()
        return w
    return uppered.join " "

module.exports = (robot) ->
    robot.hear /(^|\s)((https?:\/\/)?([\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?))/gi, (msg) ->
        target_url = msg.match[0]
        #target_url = target_url.replace /^https?:\/\//, ""
        #target_url = target_url.replace /\/$/, ""
        console.log target_url
        request { uri: target_url, method: 'GET', headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.101 Safari/537.36' } }, (error, res, body) ->
            if not error and res.statusCode == 200
                readability.read body, (err, article) ->
                    title = article.getTitle()
                    $ = cheerio.load(article.getContent())
                    imgs = $ 'img'

                    if imgs.length > 0 
                        img = imgs[0]
                    else
                        $ = cheerio.load(body)
                        imgs = $ 'img'
                        if imgs.length > 0
                            img = imgs[0]
                    
                    if img
                        img_src = img.attribs.src
                        
                        console.log img

                        # start with double slash
                        if img_src.match /^\/\//
                            img_url = "http:#{img_src}"
                        # start with double dots
                        else if img_src.match /^\.\./
                            target_url = target_url.replace /#\w*$/g , ""
                            target_url = target_url.replace /\?\w*$/g , ""
                            img_url = target_url + img_src
                        # start with single dot
                        else if img_src.match /^\./
                            target_url = target_url.replace /[^/]*$/, ""
                            img_url = target_url + img_src
                        # start with single slash
                        else if img_src.match /^\//
                            img_url = "http://#{res.request.uri.host}#{img_src}"
                        # start with http
                        else if img_src.match /^http/
                            img_url = img_src
                        else
                            target_url = target_url.replace /[^/]*$/, ""
                            img_url = target_url + img_src

                    # title: article's title
                    # img_url: article's img url
                        
                    
                    if img_url
                        console.log "[DEBUG] Image URL: #{img_url}" 
                        preview_message = "<strong>#{title}</strong><br><img width=200 src=\"#{img_url}\">"
                    else
                        preview_message = "<strong>#{title}</strong>"

                    hipchat_client = new hipchat process.env.HUBOT_HIPCHAT_TOKEN


                    # hipchat options
                    target_room = capitalize(msg.message.room)
                    msg_color = 'green'
                    from_name = 'URL Preview'

                    hipchat_msg_options = {
                        room: target_room,
                        notify: false,
                        from: from_name,
                        message: preview_message,
                        color: msg_color
                    }

                    console.log msg

                    hipchat_client.postMessage hipchat_msg_options, (api_res) ->
                        console.log "API Response:"
                        console.log api_res






