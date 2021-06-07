module Phione

export s2tw

include("words.jl")

const EOFChar = Char(0xA1) # End Of File Char

function destruct!(chn::Channel{Char}, str::AbstractString)
    temp = iterate(str)
    temp ≡ nothing && error("destruct!: string collection must be nonempty")

    char, idx = temp
    put!(chn, char)
    while true
        temp = iterate(str, idx)
        temp ≡ nothing && (put!(chn, EOFChar), break)
        char, idx = temp
        put!(chn, char)
    end
    return nothing
end

char2phr!(chn::Channel{Char}, char::Char) = haskey(WORDS, char) ? put!(chn, WORDS[char]) : put!(chn, char)

function char2phr!(cnChar::Channel{Char}, twChar::Channel{Char})
    while true
        letter = take!(cnChar)
        letter ≡ EOFChar && (put!(twChar, EOFChar), break)
        isdone = false
        if haskey(PHRASELENGTH, letter)
            maxlen = PHRASELENGTH[letter]
            phrase = string(letter)
            counts = 1
            while counts < maxlen && fetch(cnChar) ≠ EOFChar
                phrase *= take!(cnChar)
                counts += 1
                if haskey(PHRASES, phrase)
                    phrase = PHRASES[phrase]
                    isdone = true
                    break
                end
            end
            fun! = isdone ? put! : char2phr!
            temp = iterate(phrase)
            char, idx = temp
            fun!(twChar, char)
            while true
                temp = iterate(phrase, idx)
                temp ≡ nothing && break
                char, idx = temp
                fun!(twChar, char)
            end
        else
            char2phr!(twChar, letter)
        end
    end
    close(cnChar)
    return nothing
end

function assemble!(chn::Channel{Char})
    ret = ""
    while true
        temp = take!(chn)   
        temp ≡ EOFChar && (close(chn), break)
        ret *= temp
    end
    return ret
end

function s2tw(str::AbstractString)
    cnChar = Channel{Char}(16)
    twChar = Channel{Char}(16)
    @async destruct!(cnChar, str)
    @async char2phr!(cnChar, twChar)
    return fetch(@async assemble!(twChar))::String
end

end # module
