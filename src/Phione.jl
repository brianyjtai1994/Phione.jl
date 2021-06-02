module Phione

export s2tw

include("words.jl")

const EOFChar = Char(0xA1) # End Of File Char

mutable struct Status
    cnChar::Channel{Char}
    twChar::Channel{Char}
    ifdone::Channel{Bool}
    result::String
    Status() = new(Channel{Char}(16), Channel{Char}(16), Channel{Bool}(1), "")
end

function destruct!(st::Status, str::AbstractString)
    chn = st.cnChar
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

function char2phr!(st::Status)
    cnChar = st.cnChar
    twChar = st.twChar
    while true
        temp = take!(cnChar)
        temp ≡ EOFChar && (put!(twChar, EOFChar), break)
        haskey(WORDS, temp) ? put!(twChar, WORDS[temp]) : put!(twChar, temp)
    end
    close(cnChar)
    return nothing
end

function assemble!(st::Status)
    chn = st.twChar
    ret = st.result
    while true
        temp = take!(chn)   
        temp ≡ EOFChar && (close(chn), break)
        ret *= temp
    end
    st.result = ret
    put!(st.ifdone, true)
    return nothing
end

function terminate(st::Status)
    ifdone = st.ifdone
    while true
        fetch(ifdone) && (close(ifdone), break)
    end
    return st.result
end

function s2tw(str::AbstractString)
    st = Status()
    @async destruct!(st, str)
    @async char2phr!(st)
    @async assemble!(st)
    return fetch(@async terminate(st))
end

end # module
