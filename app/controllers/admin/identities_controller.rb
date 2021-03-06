class Admin::IdentitiesController < Admin::ApplicationController
  before_action :user
  before_action :identity, except: [:index, :new, :create]

  def new
    @identity = Identity.new
  end

  def create
    @identity = Identity.new(identity_params)
    @identity.user_id = user.id

    if @identity.save
      redirect_to admin_user_identities_path(@user), notice: '用户身份创建成功。'
    else
      render :new
    end
  end

  def index
    @identities = @user.identities
  end

  def edit
  end

  def update
    if @identity.update_attributes(identity_params)
      RepairLdapBlockedUserService.new(@user).execute
      redirect_to admin_user_identities_path(@user), notice: '用户身份更新成功。'
    else
      render :edit
    end
  end

  def destroy
    if @identity.destroy
      RepairLdapBlockedUserService.new(@user).execute
      redirect_to admin_user_identities_path(@user), status: 302, notice: '用户身份删除成功。'
    else
      redirect_to admin_user_identities_path(@user), status: 302, alert: '删除用户身份失败。'
    end
  end

  protected

  def user
    @user ||= User.find_by!(username: params[:user_id])
  end

  def identity
    @identity ||= user.identities.find(params[:id])
  end

  def identity_params
    params.require(:identity).permit(:provider, :extern_uid)
  end
end
