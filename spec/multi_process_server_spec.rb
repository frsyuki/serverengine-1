[ServerEngine::MultiThreadServer, ServerEngine::MultiProcessServer].each do |impl_class|
  # MultiProcessServer uses fork(2) internally, then it doesn't support Windows.

  describe impl_class do
    include_context 'test server and worker'

    it 'scale up' do
      pending "Windows environment does not support fork" if ServerEngine.windows? && impl_class == ServerEngine::MultiProcessServer

      config = {workers: 2, log_stdout: false, log_stderr: false}

      s = impl_class.new(TestWorker) { config.dup }
      t = Thread.new { s.main }

      begin
        wait_for_fork
        test_state(:worker_run).should == 2

        config[:workers] = 3
        s.reload

        wait_for_restart
        test_state(:worker_run).should == 3

        test_state(:worker_stop).should == 0

      ensure
        s.stop(true)
        t.join
      end

      test_state(:worker_stop).should == 3
    end

    it 'scale down' do
      pending "Windows environment does not support fork" if ServerEngine.windows? && impl_class == ServerEngine::MultiProcessServer

      config = {workers: 2, log_stdout: false, log_stderr: false}

      s = impl_class.new(TestWorker) { config.dup }
      t = Thread.new { s.main }

      begin
        wait_for_fork
        test_state(:worker_run).should == 2

        config[:workers] = 1
        s.restart(true)

        wait_for_restart
        test_state(:worker_run).should == 3

        test_state(:worker_stop).should == 2

      ensure
        s.stop(true)
        t.join
      end

      test_state(:worker_stop).should == 3
    end

  end
end
