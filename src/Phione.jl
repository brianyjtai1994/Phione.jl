module Phione

export s2tw

include("words.jl")

const EOFChar = Char(0xA1) # End Of File Char

function destruct!(chn::Channel{Char}, str::AbstractString)
    tmp = iterate(str)
    tmp ≡ nothing && error("destruct!: string collection must be nonempty")

    chr, idx = tmp
    put!(chn, chr)
    while true
        tmp = iterate(str, idx)
        tmp ≡ nothing && (put!(chn, EOFChar), break)
        chr, idx = tmp
        put!(chn, chr)
    end
    return nothing
end

function char2phr!(cnChar::Channel{Char}, twChar::Channel{Char})
    while true
        temp = take!(cnChar)
        temp ≡ EOFChar && (put!(twChar, EOFChar), break)
        haskey(WORDS, temp) ? put!(twChar, WORDS[temp]) : put!(twChar, temp)
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
