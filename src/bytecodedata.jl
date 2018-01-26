function readbytecoderec!(io::IO, ibuf::Vector{UInt8}, fbuf::Vector{Union{Float64,Missing}}, bias)
    ind = 1   # index into rbuffer
    for i in 1:length(ibuf)
        ind == 1 && read!(io, buf8bytes)
        ibuf[i] = b = buf8bytes[ind]
        ind = rem(ind, 8) + 1
        fbuf[i] = 0 < b < 0xfd ? Float64(b - bias) : 
              (b == 0xfd ? read(io, Float64) : (b == 0xff ? missing : zero(Float64)))
    end
end
