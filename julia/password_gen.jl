using ArgParse

const ALPHANUMS = union(Set('a':'z'), Set('A':'Z'), Set("0123456789"))
const SYMS = Set(",./?><!@#£\$%^&*()_+-=")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--length", "-l"
            help = "Length of the password"
            arg_type = Int
            default = 16
        "--nosyms"
            help = "Exclude symbols"
            action = :store_true
        "--exclude", "-e"
            help = "Exclude these chars"
            arg_type = String
            default = ""
        "--begin"
            help = "Begin with this string"
            arg_type = String
            default = ""
        "--end"
            help = "End with this string"
            arg_type = String
            default = ""
    end

    return parse_args(s)
end

function make_password(length; nosyms::Bool=false, exclude_string::AbstractString="")
    choosefrom = copy(ALPHANUMS)

    !nosyms && union!(choosefrom, SYMS)
    exclude_string != "" && setdiff!(choosefrom, Set(exclude_string))

    return String(rand(choosefrom, length))
end


function main()
    args = parse_commandline()

    password = make_password(args["length"]; nosyms=args["nosyms"], exclude_string=args["exclude"])

    begin_with = args["begin"]
    end_with = args["end"]

    println("$begin_with$password$end_with")
end

main()