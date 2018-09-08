import os
import sys
import chardet
import commands
import requests

target_jar = ['ydh', 'ircloud', 'foundation', 'grypania', 'metrics', 'tcc-transaction', 'apollo']


def run_command(command):
    status, message = commands.getstatusoutput(command)
    if status != 0:
        print command
        print message
    return message


def is_need_to_unzip(name):
    unzip_flag = False
    for item in target_jar:
        if name.find(item) != -1:
            unzip_flag = True
    return unzip_flag


def unzip_target_jar(path):
    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith('.jar'):
                if is_need_to_unzip(name):
                    run_command('unzip -q %s -d %s' % (os.path.join(root, name), os.path.join(root, name.split('.jar')[0])))
                    unzip_target_jar(os.path.join(root, name.split('.jar')[0]))


def get_md5_sum(path, result_name, tmp_dir):
    for root, dirs, files in os.walk(path):
        for name in files:
            file_path = os.path.join(root, name)
            with open(result_name, 'a+') as f:
                if name.endswith('.jar'):
                    if is_need_to_unzip(name):
                        continue
                if name == 'MANIFEST.MF' or name == 'pom.properties' or name == 'git.properties':
                    continue
                status, message = commands.getstatusoutput('md5sum "%s"' % file_path)
                f.write(message.replace('%s/' % tmp_dir, '') + '\n')


def main():
    filename = sys.argv[1]
    branch = sys.argv[2]

    if branch.find('develop') == -1:
        tmp_name = filename.split('.')[0]
        tmp_dir = 'check_md5_tmp_dir_' + tmp_name
        tmp_result_filename = filename + '_md5.log-tmp'
        result_filename = filename + '_md5.log'
        run_command('rm -r %s' % tmp_dir)
        run_command('if [ -f %s ];then rm %s; fi' % (tmp_result_filename, tmp_result_filename))
        run_command('rm %s' % result_filename)
        run_command('mkdir %s' % tmp_dir)
        run_command('unzip -q %s -d %s' % (filename, tmp_dir))
        unzip_target_jar(tmp_dir)
        get_md5_sum(tmp_dir, tmp_result_filename, tmp_dir)
        run_command('sort -k 2 %s -o %s' % (tmp_result_filename, result_filename))
        run_command('rm %s' % tmp_result_filename)
        data = ''
        with open(result_filename, 'r') as f:
            lines = f.readlines()
            for line in lines:
                data += line
        modify_time = run_command("stat %s |grep Modify |awk '{print $2,$3}'" % filename)
        requests.post('http://192.168.1.181:5000/ci/md5/update/', data={'name': filename, 'body': data,
                                                                        'env': 'intranet', 'create_time': modify_time})

    if branch.find('develop') != -1:
        modify_time = run_command("stat %s |grep Modify |awk '{print $2,$3}'" % filename)
        requests.post('http://192.168.1.181:5000/ci/md5/update/', data={'name': filename, 'body': '',
                                                                        'env': 'intranet', 'create_time': modify_time})


if __name__ == '__main__':
    main()
