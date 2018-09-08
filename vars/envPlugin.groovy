/**
 * @author chenjz
 * 2018/8/22
 */

def call() {
    def data = readJSON text: variable;
    data.each{ k, v -> env[k]=v }

    return env
}