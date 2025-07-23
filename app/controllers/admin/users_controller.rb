class Admin::UsersController < Admin::BaseController
  def index
    @users = User.includes(:test_attempts).order(:created_at)
  end
  
  def show
    @user = User.find(params[:id])
    @test_attempts = @user.test_attempts.includes(:test).order(created_at: :desc)
    @statistics = @user.test_statistics
  end
end 