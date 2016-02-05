do
    local nsq = Proto("nsq", "nsq")
    nsq.fields.content = ProtoField.string("nsq.content", "content")
    nsq.fields.type = ProtoField.string("nsq.type", "type")

    function nsq.dissector(buf, pinfo, tree)
            local t = tree:add(nsq, buf())
            local s = buf():string()
            local cmd = buf:range(0, 4):string()
            if cmd == 'IDEN' then
                t:add(nsq.fields.type, "IDENTIFY")
                local nbyte = buf:range(8+1, 4):uint()
                local json = buf:range(8+1+4, nbyte):string()
                t:add(nsq.fields.content, json)
            elseif cmd == 'SUB ' then
                -- SUB <topic_name> <channel_name>\n
                t:add(nsq.fields.type, "SUB")
                local topic, channel = s:match('^SUB%s([^%s]*)%s([^%s]*)')
                t:add(nsq.fields.content, "topic:" .. topic .." channel:" .. channel)
            elseif cmd == 'PUB ' then
                -- PUB <topic_name>\n
                -- [ 4-byte size in bytes ][ N-byte binary data ]
                t:add(nsq.fields.type, "PUB")
                local topic = s:match('^PUB (.*)\n')
                local nbyte = buf:range(4 + topic:len() + 1, 4):uint()
                local data = buf:range(4 + topic:len() + 1 + 4, nbyte)
                t:add(nsq.fields.content, "topic:" .. topic ..
                    " bytes:" .. nbyte .. " data:" ..data:string())
            elseif cmd == 'MPUB' then
                t:add(nsq.fields.type, "MPUB")
                local topic = s:match('^MPUB (.*)\n')
                local nbodybyte = buf:range(5 + topic:len() + 1, 4):uint()
                local data = buf:range(5+topic:len() + 1 + 4, nbodybyte)
                local nmessage = data:range(0, 4):uint()
                local message = data:range(4, nbodybyte-4)
                local offset = 0
                t:add(nsq.fields.content, "topic: " .. topic .. " ")
                for i=0,nmessage do
                    local nbyte = message:range(offset + 0, 4):uint()
                    local data = message:range(offset+4, nbyte)
                    offset = offset + 4 + nbyte
                    local content = "[" .. tostring(i) .. "]" .. ": " .. "bytes:" .. tostring(nbyte)
                        .. " data: " .. data:string()
                    t:add(nsq.fields.content, content)
                end

            elseif cmd == 'RDY ' then
                --RDY <count>\n
                local count = s:match('^RDY (.*)\n')
                t:add(nsq.fields.type, "RDY")
                t:add(nsq.fields.content, 'count: ' .. count)
            elseif cmd == 'FIN ' then
                --FIN <message_id>\n
                local messageid = s:match('^FIN (.*)\n');
                t:add(nsq.fields.type, "FIN")
                t:add(nsq.fields.content, 'messageid: ' .. messageid)
            elseif cmd == 'REQ ' then
                --REQ <message_id> <timeout>\n
                local message_id, timeout = s:match('^REQ ([^%s]*) ([^%s]*)\n');
                t:add(nsq.fields.type, "REQ")
                t:add(nsq.fields.content, 'messageid: ' .. messageid .. ' timeout:' .. timeout)
            elseif cmd == 'TOUC' then
                --TOUCH <message_id>\n
                local message_id, timeout = s:match('^TOUCH ([^%s]*)\n');
                t:add(nsq.fields.type, "TOUCH")
                t:add(nsq.fields.content, 'messageid: ' .. messageid)
            elseif cmd == 'CLS\n' then
                t:add(nsq.fields.type, "CLS")
            elseif cmd == 'NOP\n' then
                t:add(nsq.fields.type, "NOP")
            elseif cmd == 'AUTH' then
                --AUTH\n
                --[ 4-byte size in bytes ][ N-byte Auth Secret ]
                local nbyte = buf:range(5 + 1, 4):uint()
                t:add(nsq.fields.type, "AUTH")
                local secret = buf:range(5 + 1 + 4):string()
                t:add(nsq.fields.content, 'secret: ' .. secret)
            else
                if s:find('{.*}$') then
                    t:add(nsq.fields.content, buf():string())
                    t:add(nsq.fields.type, "reply")
                elseif s:find('.*_heartbeat_$') then
                    t:add(nsq.fields.type, "heartbeat")
                elseif s:find('OK$') then
                    t:add(nsq.fields.type, "OK")
                end
            end
    end

    tcp_table = DissectorTable.get("tcp.port")
    tcp_table:add(4150, nsq)
end